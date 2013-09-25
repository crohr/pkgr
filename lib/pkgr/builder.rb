require 'tempfile'
require 'fileutils'
require 'pkgr/config'
require 'pkgr/distribution'

module Pkgr
  class Builder
    attr_reader :tarball, :config

    def initialize(tarball, config)
      @tarball = tarball
      @config = config
    end

    def call
      setup
      extract
      compile
      package
    end

    # Setup the build directory structure
    def setup
      [
        "/usr/local/bin",
        "/opt/#{config.app_name}",
        "/etc/#{config.app_name}/conf.d",
        "/etc/default"
      ].each do |dir|
        FileUtils.mkdir_p(File.join(build_dir, dir))
      end
    end

    # Extract the given tarball to the target directory
    def extract
      raise "#{source_dir} does not exist" unless File.directory?(source_dir)

      opts = {}
      if tarball == "-"
        # FIXME: not really happy with reading everything in memory
        opts[:input] = $stdin.read
      end

      tarball_extract = Mixlib::ShellOut.new("tar xf #{tarball} -C #{source_dir}", opts)
      tarball_extract.run_command
      tarball_extract.error!
    end

    # Pass the app through the buildpack
    def compile
      if buildpack_for_app
        FileUtils.mkdir_p(compile_cache_dir)

        Pkgr.info "Found buildpack: #{buildpack_for_app}"
        buildpack_for_app.compile(source_dir, compile_cache_dir)
        buildpack_for_app.release(source_dir, compile_cache_dir)
      else
        raise Errors::UnknownAppType, "Can't find a buildpack for your app"
      end
    end

    def package
      true
    end

    # Path to the source directory containing the main app files
    def source_dir
      File.join(build_dir, "opt/#{config.app_name}")
    end

    # Build directory. Will be used by fpm to make the package
    def build_dir
      @build_dir ||= Dir.mktmpdir
    end

    # Directory where the buildpacks can store stuff
    def compile_cache_dir
      File.join(source_dir, ".git/cache")
    end

    # Current distribution we're packaging for
    def distribution
      @distribution ||= Distribution.current
    end

    # List of available buildpacks for the current distribution
    def buildpacks
      distribution.buildpacks
    end

    # Buildpack detected for the app, if any
    def buildpack_for_app
      @buildpack_for_app ||= buildpacks.find do |buildpack|
        buildpack.setup
        buildpack.detect(source_dir)
      end
    end
  end
end
