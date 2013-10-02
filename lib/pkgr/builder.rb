require 'tempfile'
require 'fileutils'
require 'pkgr/config'
require 'pkgr/distributions'
require 'pkgr/process'

module Pkgr
  class Builder
    attr_reader :tarball, :config

    # Accepts a path to a tarball (gzipped or not), or you can pass '-' to read from stdin.
    def initialize(tarball, config)
      @tarball = tarball
      @config = config
    end

    # Launch the full packaging procedure
    def call
      check
      setup
      extract
      compile
      write_env
      write_init
      package
    end

    # Check configuration, and verifies that the current distribution's requirements are satisfied
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
        puts "App detected: #{buildpack_for_app.banner}"

        FileUtils.mkdir_p(compile_cache_dir)

        Pkgr.info "Found buildpack: #{buildpack_for_app}"
        buildpack_for_app.compile(source_dir, compile_cache_dir)
        buildpack_for_app.release(source_dir, compile_cache_dir)
      else
        raise Errors::UnknownAppType, "Can't find a buildpack for your app"
      end
    end

    # Parses the output of buildpack/bin/release executable to find out its default Procfile commands.
    # Then merges those with the ones from the app's Procfile (if any).
    # Finally, generates a binstub in vendor/pkgr/processes/ so that these commands can be called using the app's executable.
    def write_env
      FileUtils.mkdir_p proc_dir

      procfile_entries.each do |process|
        process_file = File.join(proc_dir, process.name)

        File.open(process_file, "w+") do |f|
          f << process.command
          f << " $@"
        end

        FileUtils.chmod 0755, process_file
      end
    end

    # Write startup scripts.
    def write_init
      FileUtils.mkdir_p scaling_dir
      Dir.chdir(scaling_dir) do
        distribution.initializers_for(config.name, procfile_entries).each do |(process, file)|
          process_config = config.dup
          process_config.process_name = process.name
          process_config.process_command = process.command
          file.install(process_config.sesame)
        end
      end
    end

    # Launch the FPM command that will generate the package.
    def package
      Pkgr.info "Running command: #{fpm_command}"
      app_package = Mixlib::ShellOut.new(fpm_command)
      app_package.run_command
      app_package.error!
    end

    # Make sure to get rid of the build directory
    def teardown
      FileUtils.rm_rf(build_dir)
    end

    def procfile_entries
      @procfile_entries ||= begin
        default_process_types = YAML.load_file(release_file)["default_process_types"]

        entries = if File.exist?(procfile)
          File.read(procfile).gsub("\r\n","\n").split("\n").map do |line|
            if line =~ /^([A-Za-z0-9_]+):\s*(.+)$/
              [$1, $2]
            end
          end.compact
        else
          []
        end

        default_process_types.merge(Hash[entries]).map{|name, command| Process.new(name, command)}
      end
    end

    # Path to the release file generated after the buildpack compilation.
    def release_file
      File.join(source_dir, ".release")
    end

    # Path to the directory containing the main app files.
    def source_dir
      File.join(build_dir, "opt/#{config.name}")
    end

    # Build directory. Will be used by fpm to make the package.
    def build_dir
      @build_dir ||= Dir.mktmpdir
    end

    def vendor_dir
      File.join(source_dir, "vendor", "pkgr")
    end

    # Directory where binstubs will be created for the corresponding Procfile commands.
    def proc_dir
      File.join(vendor_dir, "processes")
    end

    def scaling_dir
      File.join(vendor_dir, "scaling")
    end

    # Returns the path to the app's (supposedly present) Procfile.
    def procfile
      File.join(source_dir, "Procfile")
    end

    # Directory where the buildpacks can store stuff.
    def compile_cache_dir
      config.compile_cache_dir || File.join(source_dir, ".git/cache")
    end

    # Returns the current distribution we're packaging for.
    def distribution
      @distribution ||= Distributions.current
    end

    # List of available buildpacks for the current distribution.
    def buildpacks
      distribution.buildpacks
    end

    # Buildpack detected for the app, if any.
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
