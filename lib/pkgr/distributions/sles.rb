require 'pkgr/buildpack'
require 'pkgr/process'
require 'pkgr/distributions/base'
require 'pkgr/fpm_command'

module Pkgr
  module Distributions
    class Sles < Base
      def rpm?
        true
      end

      # Only keep major digits
      def release
        @release[/^[0-9]+/]
      end

      def runner
        @runner ||= if release.to_i > 12
          Runner.new("systemd", "default", "systemctl")
        else
          Runner.new("sysv", "lsb-3.1", "chkconfig")
        end
      end

      def package_test_command(package)
        "rpm -qa '#{package}' | grep '#{package}' > /dev/null 2>&1"
      end

      def package_install_command(packages)
        # --no-gpg-checks helps with outdated repos for SLES
        zypper_flags = []
        if release.to_i <= 12
          zypper_flags.push("--no-gpg-checks")
        end
        "sudo zypper refresh ; sudo zypper #{zypper_flags.join(" ")} install -y #{packages.map{|package| "\"#{package}\""}.join(" ")}"
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
