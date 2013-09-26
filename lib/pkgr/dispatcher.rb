require 'mixlib/shellout'
require 'pkgr/builder'

module Pkgr
  class Dispatcher
    DEFAULT_APP_VERSION = "0.0.0"

    attr_reader :path, :host

    def initialize(path, opts = {})
      @path = File.expand_path(path)
      @host = opts[:host]
      @version = opts[:version]
      @name = opts[:name]
      @iteration = opts[:iteration] || Time.now.strftime("%Y%m%d%H%M%S")
      @user = opts[:user]
      @group = opts[:group]
    end

    def call
      tarify
      Builder.new(app_tarball, config)
    end

    def tarify
      system("tar czf #{app_tarball} -C \"#{path}\" .") || raise("Can't compress input directory")
    end

    def app_tarball
      (@app_tarball_file ||= Tempfile.new(["pkgr-tarball", ".tar.gz"])).path
    end

    def version
      @version || version_from_git || DEFAULT_APP_VERSION
    end

    def name
      @name || File.basename(path)
    end

    def iteration
      @iteration
    end

    def user
      @user || name
    end

    def group
      @group || user
    end

    def remote?
      !host.nil?
    end

    def git?
      File.directory?(File.join(path, ".git"))
    end

    def config
      @config ||= Pkgr::Config.new(
        :app_version => version,
        :app_name => name,
        :app_iteration => iteration,
        :app_user => user,
        :app_group => group
      )
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