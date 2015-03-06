require 'pkgr/builder'
require 'pkgr/git'

module Pkgr
  class Dispatcher
    attr_reader :path, :host, :config

    def initialize(path, opts = {})
      opts = opts.dup
      @path = path == '-' ? path : File.expand_path(path)
      @host = opts.delete(:host)
      @config = Config.new(opts)
    end

    def setup
      tarify if File.directory?(path)
    end

    def call
      setup

      if remote?
        command = %{ ( cat "#{path}" | ssh "#{host}" pkgr package - #{config.to_args.join(" ")} ) && rsync -av --include './' --include '*.deb' --include '*.rpm' --exclude '*' "#{host}":~/ .}
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
      system("tar czf #{tmpfile.path} --exclude .svn -C \"#{path}\" .") || raise(Pkgr::Errors::Base, "Can't compress input directory")
      # Remove any non-digit characters that may be before the version number
      config.version ||= begin
        v = (Git.new(path).latest_tag || "").gsub(/^[^\d]+(\d.*)/, '\1')
        # If it's not a Git archive, try to figure out svn revision number
        begin
          v = `cd #{path.to_s}&&svn info|grep Revision`.to_s.gsub!(/\D/, "") if (v !~ /^\d/)
        rescue
        end
        v = "0.0.0" if v !~ /^\d/
        v
      end
      config.name ||= File.basename(path)
      @path = tmpfile.path
    end

    def remote?
      !host.nil?
    end
  end
end
