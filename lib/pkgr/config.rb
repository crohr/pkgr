require 'ostruct'

module Pkgr
  class Config < OpenStruct
    def sesame
      binding
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
      args.push "--auto" if auto
      args.push "--verbose" if verbose
      args.push "--debug" if debug
      args
    end
  end
end
