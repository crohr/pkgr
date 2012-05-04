require 'open-uri'
require 'fileutils'
require 'pkgr'

module Pkgr
  class CLI
    include Rake::DSL

    class Error < StandardError; end
    
    attr_reader :errors
    attr_reader :uri
    attr_reader :dir
    attr_reader :config_files
    attr_reader :version
    attr_reader :name
    attr_reader :app
    attr_reader :host
    attr_reader :ref

    def initialize(opts = {})
      @errors = []
      @uri, @config_files, @version, @name, @host, @ref = opts.values_at(
        :uri, :config_files, :version, :name, :host, :ref
      )
      @app = nil
    end

    def run
      raise Error, "Can't run pkgr: #{errors.join(", ")}" unless valid?
      clone_repository
      Dir.chdir(dir) do
        checkout
        copy_remote_config_files
        copy_example_config_files
        setup
        bundle
        configure_app
        generate
        build
      end
    end

    def valid?
      @errors.clear
      @errors.push("You must pass a repository URI through --uri") if uri.nil?
      @errors.push("You must pass a version number through --bump") if version.nil?
      @errors.empty?
    end

    def build
      if host.nil?
        puts "Can't build. You must pass the --host option for this."
      else
        @app.build_debian_package(host)
      end
    end

    def bundle
      sh "bundle install"
      sh "git add -f Gemfile.lock"
      sh "git commit -m '[pkgr] Add Gemfile.lock.'"
    end

    def checkout
      pkgr_branch = "pkgr-#{ref}"
      sh "if git branch | grep '#{pkgr_branch}'; then git checkout #{pkgr_branch}; else git checkout -b #{pkgr_branch} #{ref}; fi"
    end

    def clone_repository
      parsed_uri = URI.parse(uri)
      case parsed_uri.scheme
      when nil, "file"
        @dir = parsed_uri.path
      else
        @dir = File.basename(uri, ".git")
        sh "git clone #{uri}"
      end
    end

    def configure_app
      @app = Pkgr::App.new(dir, YAML.load_file(File.join("config/pkgr.yml")))
      if name.nil?
        @app.config['name'] = File.basename(dir) if @app.name.nil?
      else
        @app.config['name'] = name
      end
      raise Error, "The app is not correctly configured: #{@app.errors.join(", ")}" unless @app.valid?
      @app.write_config
      @app.bump!(version)
    end

    # Download the given config files
    def copy_remote_config_files
      (config_files || []).each do |file|
        filename, file_uri = file.split(":")
        if file_uri.nil?
          file_uri = filename
          filename = File.basename(uri)
        end

        File.open("config/#{filename}", "w+") { |f| f << open(file_uri).read }
      end
    end

    def copy_example_config_files
      [".example", ".dist"].each do |pattern|
        Dir["config/*.yml#{pattern}"].each do |file|
          target = File.basename(file, pattern)
          unless File.exist?("config/#{target}")
            FileUtils.cp(file, "config/#{target}")
          end
        end
      end
    end

    def generate
      @app.generate_required_files
      sh "git add debian/"
      sh "git commit -m '[pkgr] Add debian files.'"
    end

    def setup
      Pkgr.setup(dir)
      File.open("Gemfile", "a") do |f|
        f.puts
        f.puts "gem 'pkgr'"
        f.puts "gem 'thin'"
      end
      sh "git add -f config/*.yml Gemfile"
      sh "git commit -m '[pkgr] Add configuration files.'"
    end
  end

end