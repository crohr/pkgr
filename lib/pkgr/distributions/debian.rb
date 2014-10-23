require 'pkgr/buildpack'
require 'pkgr/process'
require 'pkgr/distributions/base'

module Pkgr
  module Distributions
    # Contains the various components required to make a packaged app integrate well with a Debian system.
    class Debian < Base
      # Only keep major digits
      def release
        @release[/^[0-9]+/]
      end

      def runner
        @runner ||= Runner.new("sysv", "lsb-3.1", "update-rc.d")
      end

      def package_test_command(package)
        "dpkg -s '#{package}' > /dev/null 2>&1"
      end

      def package_install_command(packages)
        "sudo apt-get update && sudo apt-get install --force-yes -y #{packages.map{|package| "\"#{package}\""}.join(" ")}"
      end

      def installer_dependencies
        super.push("debianutils").uniq
      end

      def fpm_command(build_dir)
        DebianFpm.new(self, build_dir).command
      end

      def debconfig
        @debconfig ||= begin
          tmpfile = Tempfile.new("debconfig")
          tmpfile.puts "#!/bin/bash"
          tmpfile.rewind
          tmpfile
        end
        @debconfig
      end

      def debtemplates
        @debtemplates ||= Tempfile.new("debtemplates")
      end

      def add_addon(addon)
        # make a debian package out of the addon
        Dir.chdir(addon.dir) do
          make_package = Mixlib::ShellOut.new %{dpkg-buildpackage -b -d}
          make_package.logger = Pkgr.logger
          make_package.run_command
          make_package.error!
        end
        FileUtils.mv(Dir.glob(File.join(File.dirname(addon.dir), "*.deb")), Dir.pwd)
        # return name of the dependency
        addon.debian_dependency_name
      end

      class DebianFpm
        attr_reader :distribution, :build_dir, :config

        def initialize(distribution, build_dir)
          @distribution = distribution
          @build_dir = build_dir
          @config = distribution.config
        end

        def command
          %{fpm #{args.join(" ")} .}
        end

        def args
          list = []
          list << "-t deb"
          list << "-s dir"
          list << "--verbose"
          list << "--force"
          list << "--exclude '**/.git**'"
          list << %{-C "#{build_dir}"}
          list << %{-n "#{config.name}"}
          list << %{--version "#{config.version}"}
          list << %{--iteration "#{config.iteration}"}
          list << %{--url "#{config.homepage}"}
          list << %{--provides "#{config.name}"}
          list << %{--deb-user "root"}
          list << %{--deb-group "root"}
          list << %{--license "#{config.license}"} unless config.license.nil?
          list << %{-a "#{config.architecture}"}
          list << %{--description "#{config.description}"}
          list << %{--maintainer "#{config.maintainer}"}
          list << %{--template-scripts}
          list << %{--deb-config #{distribution.debconfig.path}}
          list << %{--deb-templates #{distribution.debtemplates.path}}
          list << %{--before-install #{distribution.preinstall_file}}
          list << %{--after-install #{distribution.postinstall_file}}
          list << %{--before-remove #{distribution.preuninstall_file}}
          list << %{--after-remove #{distribution.postuninstall_file}}
          distribution.dependencies(config.dependencies).each{|d| list << "-d '#{d}'"}
          list.compact
        end
      end
    end
  end
end

require 'pkgr/distributions/ubuntu'
