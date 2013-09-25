module Pkgr
  class Packager
    attr_reader :path, :config

    def initialize(path, config)
      @path = File.expand_path(path)
      @config = config
    end

    # Builds a deb out of the given path
    def call
      Dir.chdir(path) do
        "fpm -t deb -s dir -n \"#{config.app_name}\" --verbose --debug --version #{config.app_version} --iteration #{config.app_iteration} --provides \"#{config.app_name}\""
      end
    end
  end
end