require 'pkgr/buildpack'
require 'pkgr/process'
require 'pkgr/distributions/base'

module Pkgr
  module Distributions
    # Contains the various components required to make a packaged app integrate well with a Debian system.
    class Redhat < Base
      # Only keep major adigits
      def release
        @release[/^[0-9]+/]
      end

      def runner
        @runner ||= Runner.new("sysv", "lsb-3.1")
      end

      def package_test_command(package)
        "rpm -qa '#{package}' | grep '#{package}' > /dev/null 2>&1"
      end

      def package_install_command(packages)
        "sudo yum -q check-update ; sudo yum install -y #{packages.map{|package| "\"#{package}\""}.join(" ")}"
      end

      def fpm_command(build_dir, config)
        %{
          fpm -t rpm -s dir --verbose --force \
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
          --before-remove #{preremove_file(config)} \
          --after-remove #{postremove_file(config)} \
          #{dependencies(config.dependencies).map{|d| "-d '#{d}'"}.join(" ")} \
          .
        }
      end
    end
  end
end

require 'pkgr/distributions/centos'
