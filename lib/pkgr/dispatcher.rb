require 'pkgr/builder'
require 'pkgr/git'

module Pkgr
  class Dispatcher
    attr_reader :path, :host, :port, :config

    def initialize(path, opts = {})
      opts = opts.dup
      @path = path

      @host = opts.delete(:host)
      @port = opts.delete(:port)

      @config = Config.new(opts)
    end

    def setup
      tarify if File.directory?(path)
    end

    def call
      setup

      if remote?
        tarball = "/tmp/app.tar"

        command = %{set -e && \
          rm -rf #{tarball} && \
          scp -P #{port} #{path} #{host}:#{tarball} && \
          ssh #{host} -p #{port} "/bin/bash --login -c 'pkgr package #{tarball} #{config.to_args.join(" ")}'" && \
          rsync --rsh='ssh -p#{port}' "#{host}":~/*.deb .
        }

        p command
        Pkgr.debug command
        IO.popen(command) do |io|
          until io.eof?
            data = io.gets
            print data
          end
        end
        raise "Error when running remote packaging command. Please make sure to run `sudo apt-get install -y ruby1.9.1-full build-essential git-core && sudo gem install pkgr --version #{Pkgr::VERSION}`" unless $?.exitstatus.zero?
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
