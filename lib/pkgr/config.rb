require 'ostruct'
require 'yaml'

module Pkgr
  class Config < OpenStruct
    class << self
      def load_file(path, distribution)
        config = YAML.load_file(path)

        targets = config.delete("targets") || {}
        (targets[distribution.to_s] || {}).each do |k,v|
          config[k] = v
        end

        self.new(config)
      end
    end

    def sesame
      binding
    end

    def merge(other)
      new_config = self.class.new
      self.each{|k,v| new_config.send("#{k}=".to_sym, v)}
      other.each{|k,v| new_config.send("#{k}=".to_sym, v)}
      new_config
    end

    def each
      @table.each do |k,v|
        next if v.nil?
        yield k, v
      end
    end

    def home
      "/opt/#{name}"
    end

    def user
      @table[:user] || name
    end

    def group
      @table[:group] || user
    end

    def architecture
      @table[:architecture] || "x86_64"
    end

    def homepage
      @table[:homepage] || "http://example.com/no-uri-given"
    end

    def description
      @table[:description] || "No description given"
    end

    def env
      Pkgr::Env.new(@table[:env])
    end

    def valid?
      @errors = []
      @errors.push("name can't be blank") if name.nil? || name.empty?
      @errors.push("version can't be blank") if version.nil? || version.empty?
      @errors.push("iteration can't be blank") if iteration.nil? || iteration.empty?
      @errors.push("user can't be blank") if user.nil? || user.empty?
      @errors.push("group can't be blank") if group.nil? || group.empty?
      @errors.empty?
    end

    def errors
      @errors ||= []
    end

    def to_args
      args = [
        "--name \"#{name}\"",
        "--version \"#{version}\"",
        "--user \"#{user}\"",
        "--group \"#{group}\"",
        "--iteration \"#{iteration}\"",
        "--homepage \"#{homepage}\"",
        "--architecture \"#{architecture}\"",
        "--target \"#{target}\"",
        "--description \"#{description}\"",
      ]
      args.push "--dependencies #{dependencies.map{|d| "\"#{d}\""}.join("")}" unless dependencies.nil? || dependencies.empty?
      args.push "--build-dependencies #{build_dependencies.map{|d| "\"#{d}\""}.join("")}" unless build_dependencies.nil? || build_dependencies.empty?
      args.push "--compile-cache-dir \"#{compile_cache_dir}\"" unless compile_cache_dir.nil? || compile_cache_dir.empty?
      args.push "--before-precompile \"#{before_precompile}\"" unless compile_cache_dir.nil? || compile_cache_dir.empty?
      args.push "--buildpack \"#{buildpack}\"" unless buildpack.nil? || buildpack.empty?
      args.push "--env \"#{env}\"" if env.present?
      args.push "--auto" if auto
      args.push "--verbose" if verbose
      args.push "--debug" if debug
      args.push "--no-clean" if !clean
      args.push "--no-edge" if !edge
      args
    end
  end
end
