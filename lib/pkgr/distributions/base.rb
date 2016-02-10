require 'pkgr/buildpack'
require 'pkgr/env'
require 'pkgr/distributions/runner'
require 'pkgr/config'
require 'yaml'
require 'open-uri'

module Pkgr
  module Distributions
    # Base components and behaviors for all distributions.
    class Base
      attr_reader :release
      attr_writer :runner
      attr_accessor :config

      def initialize(release, config = Config.new)
        @config = config
        @release = release
      end

      def os
        self.class.name.split("::")[-1].downcase
      end # def os

      # e.g. ubuntu-12.04
      def slug
        [os, release].join("-")
      end # def slug

      def target
        {
          "centos-6" => "el:6",
          "centos-7" => "el:7"
        }.fetch(slug, slug.sub("-", ":"))
      end

      def package_test_command(package)
        raise NotImplementedError, "package_test_command must be implemented"
      end

      def package_install_command(packages)
        raise NotImplementedError, "package_install_command must be implemented"
      end

      # Check if all build dependencies are present.
      def check
        missing_packages = (build_dependencies(config.build_dependencies) || []).select do |package|
          test_command = package_test_command(package)
          Pkgr.debug "sh(#{test_command})"
          ! system(test_command)
        end

        unless missing_packages.empty?
          install_command = package_install_command(missing_packages)
          if config.auto
            puts "-----> Installing missing build dependencies: #{missing_packages.join(", ")}"
            package_install = Mixlib::ShellOut.new(install_command)
            package_install.logger = Pkgr.logger
            package_install.run_command
            package_install.error!
          else
            Pkgr.warn("Missing build dependencies detected. Run the following to fix: #{install_command}")
          end
        end
      end

      # Verifies packages
      def verify(output_dir)
        true
      end

      # e.g. data/buildpacks/ubuntu/12.04
      def default_buildpack_list
        data_file(File.join("buildpacks", slug))
      end # def default_buildpack_list

      # Returns a list of Buildpack objects
      def buildpacks
        custom_buildpack_uri = config.buildpack
        if custom_buildpack_uri
          uuid = Digest::SHA1.hexdigest(custom_buildpack_uri)
          [Buildpack.new(custom_buildpack_uri, :custom, config.env)]
        else
          load_buildpack_list
        end
      end # def buildpacks

      def dependencies(other_dependencies = nil)
        deps = YAML.load_file(data_file("dependencies", "#{os}.yml"))
        deps = {} if config.skip_default_dependencies?
        (deps["default"] || []) | (deps[slug] || []) | (other_dependencies || [])
      end # def dependencies

      def build_dependencies(other_dependencies = nil)
        deps = YAML.load_file(data_file("build_dependencies", "#{os}.yml"))
        (deps["default"] || []) | (deps[slug] || []) | (other_dependencies || [])
      end # def build_dependencies

      # Returns a list of file and directory templates.
      def templates
        app_name = config.name
        list = []

        # directories
        [
          "usr/bin",
          config.home.gsub(/^\//, ""),
          "etc/#{app_name}/conf.d",
          "etc/default",
          "var/log/#{app_name}",
          "var/db/#{app_name}",
          "usr/share/#{app_name}"
        ].each{|dir| list.push Templates::DirTemplate.new(dir) }

        list.push Templates::FileTemplate.new("etc/default/#{app_name}", data_file("environment", "default.erb"))
        list.push Templates::FileTemplate.new("etc/logrotate.d/#{app_name}", data_file("logrotate", "logrotate.erb"))

        if config.cli?
          # Put cli in /usr/bin, as redhat based distros don't have /usr/local/bin in their sudo PATH.
          list.push Templates::FileTemplate.new("usr/bin/#{app_name}", data_file("cli", "cli.sh.erb"), mode: 0755)
        end

        list
      end

      # Returns a list of <Process, FileTemplate> tuples.
      def initializers_for(app_name, procfile_entries)
        list = []
        procfile_entries.each do |process|
          Pkgr.debug "Adding #{process.inspect} to initialization scripts"
          runner.templates(process, app_name).each do |template|
            list.push [process, template]
          end
        end
        list
      end

      def crons_dir
        "etc/cron.d"
      end

      def preinstall_file
        @preinstall_file ||= generate_hook_file("preinstall.sh")
        @preinstall_file.path
      end

      def postinstall_file
        @postinstall_file ||= generate_hook_file("postinstall.sh")
        @postinstall_file.path
      end

      def preuninstall_file
        @preuninstall_file ||= generate_hook_file("preuninstall.sh")
        @preuninstall_file.path
      end

      def postuninstall_file
        @postuninstall_file ||= generate_hook_file("postuninstall.sh")
        @postuninstall_file.path
      end

      def installer_dependencies
        ["dialog", "bash"]
      end

      protected

      def load_buildpack_list
        file = config.buildpack_list || default_buildpack_list
        return [] if file.nil?

        open(file).read.split("\n").map do |line|
          url, *raw_env = line.split(",")
          buildpack_env = (config.env || Env.new).merge(Env.new(raw_env))
          Buildpack.new(url, :builtin, buildpack_env)
        end
      end # def load_buildpack_list

      def data_file(*names)
        File.new(File.join(Pkgr.data_dir, *names))
      end

      def generate_hook_file(hook_name)
        source = data_file("hooks", hook_name)
        file = Tempfile.new("postinstall")
        file.write ERB.new(File.read(source)).result(config.sesame)
        file.rewind
        file
      end

    end # class Base
  end # module Distributions
end # module Pkgr

require 'pkgr/distributions/debian'
require 'pkgr/distributions/fedora'
require 'pkgr/distributions/sles'
