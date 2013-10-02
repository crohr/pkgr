require 'pkgr/builder'

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
      if File.directory?(path)
        tmpfile = Tempfile.new(["pkgr-tarball", ".tar.gz"])
        system("tar czf #{tmpfile.path} --exclude .git -C \"#{path}\" .") || raise(Pkgr::Errors::Base, "Can't compress input directory")
        @path = tmpfile.path
      end
      Builder.new(path, config).call
    end

    def remote?
      !host.nil?
    end
  end
end