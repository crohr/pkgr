require 'pkgr/buildpack'
require 'pkgr/env'
require 'pkgr/distributions/runner'
require 'yaml'

module Pkgr
  module Distributions
    # Base components and behaviors for all distributions.
    class Base
      attr_reader :release

      def initialize(release)
        @release = release
      end

      def os
        self.class.name.split("::")[-1].downcase
      end # def osfamily

      # e.g. ubuntu-12.04
      def slug
        [os, release].join("-")
      end # def slug

      def package_test_command(package)
        raise NotImplementedError, "package_test_command must be implemented"
      end

      def package_install_command(*packages)
        raise NotImplementedError, "package_install_command must be implemented"
      end

      # Check if all build dependencies are present.
      def check(config)
        missing_packages = (build_dependencies(config.build_dependencies) || []).select do |package|
          test_command = package_test_command(package)
          Pkgr.debug "sh(#{test_command})"
          ! system(test_command)
        end

        unless missing_packages.empty?
          install_command = package_install_command(missing_packages)
          if config.auto
            package_install = Mixlib::ShellOut.new(package_install_command)
            package_install.logger = Pkgr.logger
            package_install.run_command
            package_install.error!
          else
            Pkgr.warn("Missing build dependencies detected. Run the following to fix: #{install_command}")
          end
        end
      end

      # e.g. data/buildpacks/ubuntu/12.04
      def default_buildpack_list
        data_file(File.join("buildpacks", slug))
      end # def default_buildpack_list

      # Returns a list of Buildpack objects
      def buildpacks(config)
        custom_buildpack_uri = config.buildpack
        if custom_buildpack_uri
          uuid = Digest::SHA1.hexdigest(custom_buildpack_uri)
          [Buildpack.new(custom_buildpack_uri, :custom, config.env)]
        else
          load_buildpack_list(config)
        end
      end # def buildpacks

      def dependencies(other_dependencies = nil)
        deps = YAML.load_file(data_file("dependencies", "#{os}.yml"))
        (deps["default"] || []) | (deps[slug] || []) | (other_dependencies || [])
      end # def dependencies

      def build_dependencies(other_dependencies = nil)
        deps = YAML.load_file(data_file("build_dependencies", "#{os}.yml"))
        (deps["default"] || []) | (deps[slug] || []) | (other_dependencies || [])
      end # def build_dependencies

      # Returns a list of file and directory templates.
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

        list.push Templates::FileTemplate.new("etc/default/#{app_name}", data_file("environment", "default.erb"))
        list.push Templates::FileTemplate.new("usr/local/bin/#{app_name}", data_file("cli", "cli.erb"), mode: 0755)
        list.push Templates::FileTemplate.new("etc/logrotate.d/#{app_name}", data_file("logrotate", "logrotate.erb"))

        # NOTE: conf.d files are no longer installed here, since we don't want to overwrite any pre-existing config.
        # They're now installed in the postinstall script.

        list
      end

      # Returns a list of <Process, FileTemplate> tuples.
      def initializers_for(app_name, procfile_entries)
        list = []
        procfile_entries.select(&:daemon?).each do |process|
          Pkgr.debug "Adding #{process.inspect} to initialization scripts"
          runner.templates(process, app_name).each do |template|
            list.push [process, template]
          end
        end
        list
      end

      def preinstall_file(config)
        @preinstall_file ||= generate_hook_file("preinstall.sh", config)
        @preinstall_file.path
      end

      def postinstall_file(config)
        @postinstall_file ||= generate_hook_file("postinstall.sh", config)
        @postinstall_file.path
      end

      protected

      def load_buildpack_list(config)
        file = config.buildpack_list || default_buildpack_list
        return [] if file.nil?

        File.read(file).split("\n").map do |line|
          url, *raw_env = line.split(",")
          buildpack_env = (config.env || Env.new).merge(Env.new(raw_env))
          Buildpack.new(url, :builtin, buildpack_env)
        end
      end # def load_buildpack_list

      def data_file(*names)
        File.new(File.join(Pkgr.data_dir, *names))
      end

      def generate_hook_file(hook_name, config)
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
require 'pkgr/distributions/ubuntu'
