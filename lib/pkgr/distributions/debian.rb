require 'pkgr/buildpack'
require 'pkgr/process'
require 'yaml'
require 'erb'

module Pkgr
  module Distributions
    class Debian

      # Must be subclassed.
      def codename
        raise NotImplementedError, "codename must be set"
      end

      def osfamily
        "debian"
      end

      def slug
        [osfamily, codename].join("-")
      end

      def templates(app_name)
        list = []

        # directories
        [
          "usr/local/bin",
          "opt/#{app_name}",
          "etc/#{app_name}/conf.d",
          "etc/default",
          "etc/init",
          "var/log/#{app_name}"
        ].each{|dir| list.push Templates::DirTemplate.new(dir) }

        # default
        list.push Templates::FileTemplate.new("etc/default/#{app_name}", File.new(File.join(data_dir, "default.erb")))
        # upstart master
        list.push Templates::FileTemplate.new("etc/init/#{app_name}.conf", data_file("upstart/master.conf.erb"))
        # executable
        list.push Templates::FileTemplate.new("usr/local/bin/#{app_name}", File.new(File.join(data_dir, "runner.erb")), mode: 0755)
        # logrotate
        list.push Templates::FileTemplate.new("etc/logrotate.d/#{app_name}", File.new(File.join(data_dir, "logrotate.erb")))

        # NOTE: conf.d files are no longer installed here, since we don't want to overwrite any pre-existing config.
        # They're now installed in the postinstall script.

        list
      end

      def initializers_for(app_name, procfile_entries)
        list = []
        procfile_entries.select(&:daemon?).each do |process|
          Pkgr.debug "Adding #{process.inspect} to initialization scripts"
          list.push [process, Templates::FileTemplate.new("#{app_name}-#{process.name}.conf", data_file("upstart/process_master.conf.erb"))]
          list.push [process, Templates::FileTemplate.new("#{app_name}-#{process.name}-PROCESS_NUM.conf", data_file("upstart/process.conf.erb"))]
        end
        list
      end

      def check(config)
        missing_packages = (build_dependencies(config.build_dependencies) || []).select do |package|
          test_command = "dpkg -s '#{package}' > /dev/null 2>&1"
          Pkgr.debug "sh(#{test_command})"
          ! system(test_command)
        end

        unless missing_packages.empty?
          package_install_command = "sudo apt-get install -y #{missing_packages.map{|package| "\"#{package}\""}.join(" ")}"
          if config.auto
            package_install = Mixlib::ShellOut.new(package_install_command)
            package_install.logger = Pkgr.logger
            package_install.run_command
            package_install.error!
          else
            Pkgr.warn("Missing build dependencies detected. Run the following to fix: #{package_install_command}")
          end
        end
      end

      def fpm_command(build_dir, config)
        %{
          fpm -t deb -s dir  --verbose --force \
          -C "#{build_dir}" \
          -n "#{config.name}" \
          --version "#{config.version}" \
          --iteration "#{config.iteration}" \
          --url "#{config.homepage}" \
          --provides "#{config.name}" \
          --deb-user "root" \
          --deb-group "root" \
          -a "#{config.architecture}" \
          --description "#{config.description}" \
          --template-scripts \
          --before-install #{preinstall_file(config)} \
          --after-install #{postinstall_file(config)} \
          #{dependencies(config.dependencies).map{|d| "-d '#{d}'"}.join(" ")} \
          .
        }
      end

      def buildpacks(config)
        custom_buildpack_uri = config.buildpack
        if custom_buildpack_uri
          uuid = Digest::SHA1.hexdigest(custom_buildpack_uri)
          [Buildpack.new(custom_buildpack_uri, :custom, config.env)]
        else
          default_buildpacks.map{|url| Buildpack.new(url, :builtin, config.env)}
        end
      end

      # Return the default buildpacks. Must be subclassed.
      def default_buildpacks
        []
      end

      def preinstall_file(config)
        @preinstall_file ||= begin
          source = File.join(data_dir, "hooks", "preinstall.sh")
          file = Tempfile.new("preinstall")
          file.write ERB.new(File.read(source)).result(config.sesame)
          file.rewind
          file
        end

        @preinstall_file.path
      end

      def postinstall_file(config)
        @postinstall_file ||= begin
          source = File.join(data_dir, "hooks", "postinstall.sh")
          file = Tempfile.new("postinstall")
          file.write ERB.new(File.read(source)).result(config.sesame)
          file.rewind
          file
        end

        @postinstall_file.path
      end

      def dependencies(other_dependencies = nil)
        deps = YAML.load_file(File.join(data_dir, "dependencies.yml"))
        (deps["default"] || []) | (deps[codename] || []) | (other_dependencies || [])
      end

      def build_dependencies(other_dependencies = nil)
        deps = YAML.load_file(File.join(data_dir, "build_dependencies.yml"))
        (deps["default"] || []) | (deps[codename] || []) | (other_dependencies || [])
      end

      def data_file(name)
        File.new(File.join(data_dir, name))
      end

      def data_dir
        File.join(Pkgr.data_dir, "distributions", "debian")
      end
    end
  end
end

%w{debian_squeeze debian_wheezy ubuntu_lucid ubuntu_precise}.each do |distro|
  require "pkgr/distributions/#{distro}"
end
