require 'pkgr/buildpack'
require 'pkgr/process'
require 'pkgr/distributions/base'
require 'pkgr/fpm_command'

module Pkgr
  module Distributions
    class Sles < Base
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
        "sudo zypper refresh ; sudo zypper install -y #{packages.map{|package| "\"#{package}\""}.join(" ")}"
      end

      def installer_dependencies
        if release.to_i > 11
          super.push("which").push("net-tools").uniq
        else
          # sles-11 already has which installed
          super.push("net-tools").uniq
        end
      end

      def fpm_command(build_dir)
        SlesFpmCommand.new(self, build_dir).command
      end

      class SlesFpmCommand < FpmCommand
        def args
          list = super
          list << "-t" << "rpm"
          list
        end
      end
    end
  end
end
