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
        %{fpm #{fpm_args(build_dir, config).join(" ")} .}
      end

      def fpm_args(build_dir, config)
        args = []
        args << "-t deb"
        args << "-s dir"
        args << "--verbose"
        args << "--force"
        args << "--exclude '**/.git**'"
        args << %{-C "#{build_dir}"}
        args << %{-n "#{config.name}"}
        args << %{--version "#{config.version}"}
        args << %{--iteration "#{config.iteration}"}
        args << %{--url "#{config.homepage}"}
        args << %{--provides "#{config.name}"}
        args << %{--deb-user "root"}
        args << %{--deb-group "root"}
        args << %{--license "#{config.license}"} unless config.license.nil?
        args << %{-a "#{config.architecture}"}
        args << %{--description "#{config.description}"}
        args << %{--maintainer "#{config.maintainer}"}
        args << %{--template-scripts}
        args << %{--before-install #{preinstall_file(config)}}
        args << %{--after-install #{postinstall_file(config)}}
        dependencies(config.dependencies).each{|d| args << "-d '#{d}'"}
        args
      end
    end
  end
end

require 'pkgr/distributions/ubuntu'
