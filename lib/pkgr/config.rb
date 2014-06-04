require 'ostruct'
require 'yaml'
require 'pathname'
require 'base64'

module Pkgr
  class Config < OpenStruct
    DISTRO_COMPATIBILITY_MAPPING = {
      "ubuntu-lucid" => "ubuntu-10.04",
      "ubuntu-precise" => "ubuntu-12.04",
      "debian-squeeze" => "debian-6",
      "debian-wheezy" => "debian-7"
    }

    class << self
      def load_file(path, distribution)
        config = YAML.load_file(path) || {}
        Pkgr.debug "Configuration from file: #{config.inspect} - Distribution: #{distribution.inspect}."

        targets = config.delete("targets") || {}

        # backward compatibility
        DISTRO_COMPATIBILITY_MAPPING.each do |from, to|
          if targets.has_key?(from)
            targets[to] = targets.delete(from)
          end
        end

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
      self.each{|k,v|
        new_value = case v
        when Array
          v | (other.delete(k) || [])
        else
          v
        end
        new_config.send("#{k}=".to_sym, new_value)
      }
      other.each{|k,v| new_config.send("#{k}=".to_sym, v)}
      new_config
    end

    def each
      @table.each do |k,v|
        next if v.nil?
        yield k, v
      end
    end

    def delete(key)
      @table.delete(key)
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

    def maintainer
      @table[:maintainer] || "<someone@pkgr>"
    end

    def env
      Pkgr::Env.new(@table[:env])
    end

    def valid?
      @errors = []
      @errors.push("name can't be blank") if name.nil? || name.empty?
      @errors.push("version can't be blank") if version.nil? || version.empty?
      @errors.push("version must start with a digit") if !version.empty? && version !~ /^\d/
      @errors.push("iteration can't be blank") if iteration.nil? || iteration.empty?
      @errors.push("user can't be blank") if user.nil? || user.empty?
      @errors.push("group can't be blank") if group.nil? || group.empty?
      @errors.empty?
    end

    def errors
      @errors ||= []
    end

    def before_hook
      if before_precompile.nil? || before_precompile.empty?
        before_steps = self.before || []

        if before_steps.empty?
          nil
        else
          tmpfile = Tempfile.new(["before_hook", ".sh"])
          before_steps.each{|step| tmpfile.puts step}
          tmpfile.close
          tmpfile.path
        end
      else
        before_precompile
      end
    end

    def after_hook
      if after_precompile.nil? || after_precompile.empty?
        after_steps = self.after || []

        if after_steps.empty?
          nil
        else
          tmpfile = Tempfile.new(["after_hook", ".sh"])
          after_steps.each{|step| tmpfile.puts step}
          tmpfile.close
          tmpfile.path
        end
      else
        after_precompile
      end
    end

    def before_install
      return nil if @table[:before_install].nil?
      Pathname.new(source_dir).join(@table[:before_install]).realpath.to_s
    end

    def after_install
      return nil if @table[:after_install].nil?
      Pathname.new(source_dir).join(@table[:after_install]).realpath.to_s
    end

    # TODO: DRY this with cli.rb
    def to_args
      args = [
        "--name \"#{name}\"",
        "--version \"#{version}\"",
        "--user \"#{user}\"",
        "--group \"#{group}\"",
        "--iteration \"#{iteration}\"",
        "--homepage \"#{homepage}\"",
        "--architecture \"#{architecture}\"",
        "--description \"#{description}\"",
        "--maintainer \"#{maintainer}\""
      ]
      args.push "--dependencies #{dependencies.map{|d| "\"#{d}\""}.join}" unless dependencies.nil? || dependencies.empty?
      args.push "--build-dependencies #{build_dependencies.map{|d| "\"#{d}\""}.join}" unless build_dependencies.nil? || build_dependencies.empty?
      args.push "--compile-cache-dir \"#{compile_cache_dir}\"" unless compile_cache_dir.nil? || compile_cache_dir.empty?
      args.push "--before-precompile \"#{before_precompile}\"" unless before_precompile.nil? || before_precompile.empty?
      args.push "--after-precompile \"#{after_precompile}\"" unless after_precompile.nil? || after_precompile.empty?
      args.push "--before-install \"#{before_install}\"" unless before_install.nil? || before_install.empty?
      args.push "--after-install \"#{after_install}\"" unless after_install.nil? || after_install.empty?
      args.push "--license \"#{license}\"" unless license.nil? || license.empty?
      args.push "--buildpack \"#{buildpack}\"" unless buildpack.nil? || buildpack.empty?
      args.push "--buildpack_list \"#{buildpack_list}\"" unless buildpack_list.nil? || buildpack_list.empty?
      args.push "--force-os \"#{force_os}\"" unless force_os.nil? || force_os.empty?
      args.push "--runner \"#{runner}\"" unless runner.nil? || runner.empty?
      args.push "--env #{env.variables.map{|v| "\"#{v}\""}.join(" ")}" if env.present?
      args.push "--auto" if auto
      args.push "--verbose" if verbose
      args.push "--store-cache" if store_cache
      args.push "--debug" if debug
      args.push "--no-clean" if !clean
      args.push "--no-edge" if !edge
      args
    end
  end
end
