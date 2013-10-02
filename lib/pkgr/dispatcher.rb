require 'pkgr/builder'
require 'pkgr/git'

module Pkgr
  class Dispatcher
    attr_reader :path, :host, :config

    def initialize(path, opts = {})
      opts = opts.dup
      @path = File.expand_path(path)
      @host = opts.delete(:host)
      @config = Config.new(opts)
    end

    def call
      tarify if File.directory?(path)
      if remote?
      else
        Builder.new(path, config).call
      end
    end

    def tarify
      tmpfile = Tempfile.new(["pkgr-tarball", ".tar.gz"])
      system("tar czf #{tmpfile.path} --exclude .git --exclude .svn -C \"#{path}\" .") || raise(Pkgr::Errors::Base, "Can't compress input directory")
      # Remove any non-digit characters that may be before the version number
      config.version ||= (Git.new(path).latest_tag || "").gsub(/^[^\d](\d.*)/, '\1')
      config.compile_cache_dir ||= File.join(path, ".git", "cache")
      config.name ||= File.basename(path)
      @path = tmpfile.path
    end

    def remote?
      !host.nil?
    end
  end
end