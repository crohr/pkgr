require 'pkgr/buildpack'
require 'pkgr/process'
require 'pkgr/distributions/base'

module Pkgr
  module Distributions
    # Contains the various components required to make a packaged app integrate well with a Debian system.
    class Debian < Base
      # Only keep major and minor digits
      def release
        @release[/^[0-9]+\.[0-9]+/]
      end

      def runner
        Runner.new("sysv", "lsb-3.1")
      end

      def package_test_command(package)
        "dpkg -s '#{package}' > /dev/null 2>&1"
      end

      def package_install_command(*packages)
        "sudo apt-get update && sudo apt-get install --force-yes -y #{packages.map{|package| "\"#{package}\""}.join(" ")}"
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
    end
  end
end

require 'pkgr/distributions/ubuntu'
