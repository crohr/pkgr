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
        @runner ||= Runner.new("sysv", "lsb-3.1")
      end

      def package_test_command(package)
        "dpkg -s '#{package}' > /dev/null 2>&1"
      end

      def package_install_command(packages)
        "sudo apt-get update && sudo apt-get install --force-yes -y #{packages.map{|package| "\"#{package}\""}.join(" ")}"
      end

      def fpm_command(build_dir, config)
        DebianFpm.new(self, build_dir, config).command
      end

      class DebianFpm
        attr_reader :distribution, :build_dir, :config

        def initialize(distribution, build_dir, config)
          @distribution = distribution
          @build_dir = build_dir
          @config = config
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
          list << debconfig
          list << debtemplates
          list << %{--before-install #{distribution.preinstall_file(config)}}
          list << %{--after-install #{distribution.postinstall_file(config)}}
          distribution.dependencies(config.dependencies).each{|d| list << "-d '#{d}'"}
          list.compact
        end

        def debconfig
          debconfig_file = Tempfile.new("debconfig")
          debconfig_file.write "#!/bin/bash"
          config.addons.each do |addon|
            debconfig_file.write addon.config.read
          end
          expected_debconfig_file = File.join(build_dir, config.home, "debian", "config")
          if File.exists?(expected_debconfig_file)
            %{--deb-config "#{expected_debconfig_file}"}
          end
        end

        def debtemplates
          expected_debtemplates_file = File.join(build_dir, config.home, "debian", "templates")
          if File.exists?(expected_debtemplates_file)
            %{--deb-templates "#{expected_debtemplates_file}"}
          end
        end

      end
    end
  end
end

require 'pkgr/distributions/ubuntu'
