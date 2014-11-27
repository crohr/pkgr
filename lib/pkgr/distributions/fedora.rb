require 'pkgr/buildpack'
require 'pkgr/process'
require 'pkgr/distributions/base'

module Pkgr
  module Distributions
    # Contains the various components required to make a packaged app integrate well with a Debian system.
    class Fedora < Base
      # Only keep major digits
      def release
        @release[/^[0-9]+/]
      end

      def runner
        @runner ||= Runner.new("sysv", "lsb-3.1", "chkconfig")
      end

      def package_test_command(package)
        "rpm -qa '#{package}' | grep '#{package}' > /dev/null 2>&1"
      end

      def package_install_command(packages)
        "sudo yum -q check-update ; sudo yum install -y #{packages.map{|package| "\"#{package}\""}.join(" ")}"
      end

      def installer_dependencies
        super.push("which").uniq
      end

      def fpm_command(build_dir)
        "fpm #{fpm_args(build_dir).join(" ")}"
      end

      private

        def fpm_args(build_dir)
          args = []
          args << %{-t rpm}
          args << %{-s dir}
          args << %{--verbose}
          args << %{--force}
          args << %{--exclude '**/.git**'}
          args << %{-C "#{build_dir}"}
          args << %{-n "#{config.name}"}
          args << %{--version "#{config.version}"}
          args << %{--iteration "#{config.iteration}"}
          args << %{--url "#{config.homepage}"}
          args << %{--provides "#{config.name}"}
          args << %{--license "#{config.license}"} if config.license
          args << %{--deb-user root}
          args << %{--deb-group root}
          args << %{--vendor "#{config.vendor}"}
          args << %{-a "#{config.architecture}"}
          args << %{--description "#{config.description}"}
          args << %{--maintainer "#{config.maintainer}"}
          args << %{--template-scripts}
          args << %{--before-install "#{preinstall_file}"}
          args << %{--after-install "#{postinstall_file}"}
          args << %{--before-remove "#{preuninstall_file}"}
          args << %{--after-remove "#{postuninstall_file}"}
          args << dependencies(config.dependencies).map{|d| "-d '#{d}'"}.join(" ")
          args << "."
        end
    end
  end
end

require 'pkgr/distributions/redhat'
require 'pkgr/distributions/centos'
