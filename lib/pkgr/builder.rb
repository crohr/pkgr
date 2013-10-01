require 'tempfile'
require 'fileutils'
require 'pkgr/config'
require 'pkgr/distributions'

module Pkgr
  class Builder
    attr_reader :tarball, :config

    def initialize(tarball, config)
      @tarball = tarball
      @config = config
    end

    def call
      check
      setup
      extract
      compile
      package
    end

    def check
      raise Errors::ConfigurationInvalid, config.errors.join("; ") unless config.valid?

      distribution.requirements.each do |package|
        system("dpkg -l '#{package}' >/dev/null") || Pkgr.debug("Can't find package `#{package}`. Further steps may fail.")
      end
    end

    # Setup the build directory structure
    def setup
      Dir.chdir(build_dir) do
        distribution.templates(config.name).each do |template|
          template.install(config.sesame)
        end
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

      tarball_extract = Mixlib::ShellOut.new("tar xzf #{tarball} -C #{source_dir}", opts)
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
      Pkgr.info "Running command: #{fpm_command}"
      app_package = Mixlib::ShellOut.new(fpm_command)
      app_package.run_command
      app_package.error!
    end

    def teardown
      FileUtils.rm_rf(build_dir)
    end

    # Path to the source directory containing the main app files
    def source_dir
      File.join(build_dir, "opt/#{config.name}")
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
      @distribution ||= Distributions.current
    end

    # List of available buildpacks for the current distribution
    def buildpacks
      distribution.buildpacks
    end

    # Buildpack detected for the app, if any
    def buildpack_for_app
      raise "#{source_dir} does not exist" unless File.directory?(source_dir)
      @buildpack_for_app ||= buildpacks.find do |buildpack|
        buildpack.setup
        buildpack.detect(source_dir)
      end
    end

    def fpm_command
      distribution.fpm_command(build_dir, config)
    end
  end
end
