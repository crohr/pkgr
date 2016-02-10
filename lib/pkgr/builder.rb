require 'tempfile'
require 'fileutils'
require 'pkgr/config'
require 'pkgr/distributions'
require 'pkgr/process'
require 'pkgr/addon'
require 'pkgr/cron'
require 'pkgr/installer'

module Pkgr
  class Builder
    attr_reader :tarball, :config

    # Accepts a path to a tarball (gzipped or not), or you can pass '-' to read from stdin.
    def initialize(tarball, config)
      @tarball = tarball
      @config = config
      Pkgr.debug "Initializing builder with the following config: #{config.inspect}"
    end

    # Launch the full packaging procedure
    def call
      extract
      update_config
      check
      setup
      setup_pipeline
      compile
      write_env
      write_init
      setup_crons
      package
      store_cache
    ensure
      teardown if config.clean
    end

    # Extract the given tarball to the target directory
    def extract
      FileUtils.mkdir_p source_dir

      opts = {}
      if tarball == "-"
        # FIXME: not really happy with reading everything in memory
        opts[:input] = $stdin.read
      end

      tarball_extract = Mixlib::ShellOut.new("tar xzf #{tarball} -C #{source_dir}", opts)
      tarball_extract.logger = Pkgr.logger
      tarball_extract.run_command
      tarball_extract.error!
    end

    # Update existing config with the one from .pkgr.yml file, if any
    def update_config
      if File.exist?(config_file)
        Pkgr.debug "Loading #{distribution.slug} from #{config_file}."
        @config = Config.load_file(config_file, distribution.slug).merge(config)
        Pkgr.debug "Found .pkgr.yml file. Updated config is now: #{config.inspect}"

        # update distribution config
        distribution.config = @config

        # FIXME: make Config the authoritative source of the runner config (distribution only tells the default runner)
        if @config.runner
          type, *version = @config.runner.split("-")
          distribution.runner = Distributions::Runner.new(type, version.join("-"))
        end
      end
      config.distribution = distribution
      config.env.variables.push("TARGET=#{distribution.target}")
      # useful for templates that need to read files
      config.source_dir = source_dir
      config.build_dir = build_dir
    end

    def pipeline
      @pipeline ||= begin
        components = []
        unless config.wizards.empty? || config.installer == false
          components << Installer.new(config.installer, distribution).setup
        end
        components
      end
    end

    # Check configuration, and verifies that the current distribution's requirements are satisfied
    def check
      raise Errors::ConfigurationInvalid, config.errors.join("; ") unless config.valid?
      distribution.check
    end

    # Setup the build directory structure
    def setup
      Dir.chdir(build_dir) do
        distribution.templates.each do |template|
          template.install(config.sesame)
        end
      end
    end

    def setup_pipeline
      pipeline.each do |component|
        @config = component.call(config)
      end
    end

    # Pass the app through the buildpack
    def compile
      if buildpack_for_app
        puts "-----> #{buildpack_for_app.banner} app"

        begin
          FileUtils.mkdir_p(app_home_dir)
        rescue Errno::EACCES => e
          Pkgr.logger.warn "Can't create #{app_home_dir.inspect}, which may be needed by some buildpacks."
        end
        FileUtils.mkdir_p(compile_cache_dir)
        FileUtils.mkdir_p(compile_env_dir)

        run_hook config.before_hook
        buildpack_for_app.compile(source_dir, compile_cache_dir, compile_env_dir)
        buildpack_for_app.release(source_dir)
        run_hook config.after_hook
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
          f.puts "#!/bin/sh"
          f << "exec "
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

    # Write cron files
    def setup_crons
      crons_dir = File.join("/", distribution.crons_dir)

      config.crons.map! do |cron_path|
        Cron.new(File.expand_path(cron_path, config.home), File.join(crons_dir, File.basename(cron_path)))
      end

      config.crons.each do |cron|
        puts "-----> [cron] #{cron.source} => #{cron.destination}"
      end
    end


    # Launch the FPM command that will generate the package.
    def package(remaining_attempts = 3)
      app_package = Mixlib::ShellOut.new(fpm_command)
      app_package.logger = Pkgr.logger
      app_package.run_command
      app_package.error!
      begin
        verify
      rescue Mixlib::ShellOut::ShellCommandFailed => e
        if remaining_attempts > 0
          package(remaining_attempts - 1)
        else
          raise
        end
      end
    end

    def verify
      return true unless config.verify
      distribution.verify(Dir.pwd)
    end

    def store_cache
      return true unless config.store_cache
      generate_cache_tarball = Mixlib::ShellOut.new %{tar czf cache.tar.gz -C #{compile_cache_dir} .}
      generate_cache_tarball.logger = Pkgr.logger
      generate_cache_tarball.run_command
    end

    # Make sure to get rid of the build directory
    def teardown
      FileUtils.rm_rf(build_dir)
    end

    def procfile_entries
      @procfile_entries ||= begin
        default_process_types = YAML.load_file(release_file)["default_process_types"]

        default_process_types = {} unless default_process_types

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

    def config_file
      File.join(source_dir, ".pkgr.yml")
    end

    # Path to the directory containing the main app files.
    def source_dir
      File.join(build_dir, config.home)
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

    # Some buildpacks may need the target home dir to exist
    def app_home_dir
      config.home
    end

    # Directory where the buildpacks can store stuff.
    def compile_cache_dir
      config.compile_cache_dir || File.join(source_dir, ".git/cache")
    end

    # Directory where the buildpacks can store config envs.
    def compile_env_dir
      config.compile_env_dir ||= Dir.mktmpdir
    end

    # Returns the current distribution we're packaging for.
    def distribution
      @distribution ||= Distributions.current(config)
    end

    # List of available buildpacks for the current distribution.
    def buildpacks
      distribution.buildpacks
    end

    # Buildpack detected for the app, if any.
    def buildpack_for_app
      raise "#{source_dir} does not exist" unless File.directory?(source_dir)
      @buildpack_for_app ||= buildpacks.find do |buildpack|
        buildpack.setup(config.edge, config.home)
        buildpack.detect(source_dir)
      end
    end

    def fpm_command
      distribution.fpm_command(build_dir)
    end

    protected
    def run_hook(file)
      return true if file.nil?

      cmd = %{env -i APP_NAME="#{config.name}" PATH="$PATH"#{config.env} bash '#{file}' 2>&1}

      Pkgr.logger.debug "Running hook in #{source_dir}: #{file.inspect}"
      puts "-----> Running hook: #{file.inspect}"

      Dir.chdir(source_dir) do
        IO.popen(cmd) do |io|
          until io.eof?
            data = io.gets
            print "       #{data}"
          end
        end
        raise "Hook failed" unless $?.exitstatus.zero?
      end
    end
  end
end
