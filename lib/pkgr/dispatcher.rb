require 'mixlib/shellout'

module Pkgr
  class Dispatcher
    DEFAULT_APP_VERSION = "0.0.0"

    attr_reader :path, :host

    def initialize(path, opts = {})
      @path = File.expand_path(path)
      @host = opts[:host]
      @app_version = opts[:version]
    end

    def call
    end

    def app_version
      @app_version || version_from_git || DEFAULT_APP_VERSION
    end

    def remote?
      !host.nil?
    end

    def git?
      File.directory?(File.join(path, ".git"))
    end

    private
    def version_from_git
      if git?
        Dir.chdir(path) do
          git_describe = Mixlib::ShellOut.new("git describe --tags --abbrev=0")
          git_describe.run_command
          @app_version = git_describe.stdout.chomp
        end
      end
    end
  end
end