require 'pkgr/buildpack'
require 'pkgr/process'
require 'pkgr/distributions/base'
require 'pkgr/fpm_command'

module Pkgr
  module Distributions
    # Contains the various components required to make a packaged app integrate well with a Debian system.
    class Debian < Base
      # Only keep major digits
      def release
        @release[/^[0-9]+/]
      end

      def runner
        @runner ||= case release
        when /^8/, /^9/
          Runner.new("systemd", "default", "systemctl")
        else
          Runner.new("sysv", "lsb-3.1", "update-rc.d")
        end
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
        DebianFpmCommand.new(self, build_dir).command
      end

      def verify(output_dir)
        Dir.glob(File.join(output_dir, "*deb")).each do |package|
          puts "-----> Verifying package #{File.basename(package)}"
          Dir.mktmpdir do |dir|
            verify_package = Mixlib::ShellOut.new %{dpkg-deb -x #{package} #{dir}}
            verify_package.logger = Pkgr.logger
            verify_package.run_command
            verify_package.error!
          end
        end
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

      class DebianFpmCommand < FpmCommand
        def args
          list = super
          list << "-t" << "deb"
          list << "--deb-user" << "root"
          list << "--deb-group" << "root"
          list
        end
      end
    end
  end
end

require 'pkgr/distributions/ubuntu'
