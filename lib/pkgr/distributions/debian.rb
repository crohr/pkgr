require 'pkgr/buildpack'
require 'pkgr/process'
require 'pkgr/distributions/base'
require 'yaml'
require 'erb'

module Pkgr
  module Distributions
    class Debian < Base

      def osfamily
        "debian"
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
          # sysvinit
          list.push [process, Templates::FileTemplate.new("sysv/#{app_name}", data_file("sysv/master.erb"))]
          list.push [process, Templates::FileTemplate.new("sysv/#{app_name}-#{process.name}", data_file("sysv/process_master.erb"))]
          list.push [process, Templates::FileTemplate.new("sysv/#{app_name}-#{process.name}-PROCESS_NUM", data_file("sysv/process.erb"))]
          # upstart
          list.push [process, Templates::FileTemplate.new("upstart/#{app_name}", data_file("upstart/init.d.sh.erb"))]
          list.push [process, Templates::FileTemplate.new("upstart/#{app_name}.conf", data_file("upstart/master.conf.erb"))]
          list.push [process, Templates::FileTemplate.new("upstart/#{app_name}-#{process.name}.conf", data_file("upstart/process_master.conf.erb"))]
          list.push [process, Templates::FileTemplate.new("upstart/#{app_name}-#{process.name}-PROCESS_NUM.conf", data_file("upstart/process.conf.erb"))]
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
          package_install_command = "sudo apt-get update && sudo apt-get install --force-yes -y #{missing_packages.map{|package| "\"#{package}\""}.join(" ")}"
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
          --maintainer "#{config.maintainer}" \
          --template-scripts \
          --before-install #{preinstall_file(config)} \
          --after-install #{postinstall_file(config)} \
          #{dependencies(config.dependencies).map{|d| "-d '#{d}'"}.join(" ")} \
          .
        }
      end

      def default_buildpack_list
        data_file(File.join("buildpacks", "#{osfamily}_#{codename}"))
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
