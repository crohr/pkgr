require 'shellwords'

module Pkgr
  class FpmCommand
    attr_reader :distribution, :build_dir, :config

    def initialize(distribution, build_dir)
      @distribution = distribution
      @build_dir = build_dir
      @config = distribution.config
    end

    def command
      %{fpm #{Shellwords.join(args)} .}
    end

    def args
      list = []
      list << "-s" << "dir"
      list << "--verbose"
      list << "--force"
      list << "--exclude" << "**/.git**"
      list << "-C" << build_dir
      list << "-n" << config.name
      list << "--version" << config.version
      list << "--iteration" << config.iteration
      list << "--url" << config.homepage
      list << "--provides" << config.name
      list << "--license" << config.license unless config.license.nil?
      list << "-a" << config.architecture
      list << "--description" << config.description
      list << "--maintainer" << config.maintainer
      list << "--vendor" << config.vendor
      list << "--category" << config.category
      list << "--template-scripts"
      list << "--before-install" << distribution.preinstall_file
      list << "--after-install" << distribution.postinstall_file
      list << "--before-remove" << distribution.preuninstall_file
      list << "--after-remove" << distribution.postuninstall_file
      list << "--directories" << config.directories unless config.directories.nil?
      distribution.dependencies(config.dependencies).each{|d| list << "-d" << d}
      list.compact
    end
  end
end
