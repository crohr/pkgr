require 'fileutils'
require 'digest/sha1'

module Pkgr
  class Buildpack
    class << self
      attr_writer :buildpacks_cache_dir

      def buildpacks_cache_dir
        @buildpacks_cache_dir ||= File.expand_path("~/.pkgr/buildpacks").tap do |dir|
          FileUtils.mkdir_p(dir)
        end
      end
    end

    attr_reader :url, :banner, :type, :uuid, :branch, :env

    def initialize(url, type = :builtin, env = nil)
      @uuid = Digest::SHA1.hexdigest(url)
      @url, @branch = url.split("#")
      @branch ||= "master"
      @type = type
      @env = env
    end

    def buildpack_cache_dir
      File.join(self.class.buildpacks_cache_dir, type.to_s, uuid)
    end

    def detect(path)
      buildpack_detect = Mixlib::ShellOut.new("#{dir}/bin/detect \"#{path}\"")
      buildpack_detect.logger = Pkgr.logger
      buildpack_detect.run_command
      @banner = buildpack_detect.stdout.chomp
      buildpack_detect.exitstatus == 0
    end

    def compile(path, compile_cache_dir, compile_env_dir)
      cmd = %{env -i PATH="$PATH"#{env} #{dir}/bin/compile "#{path}" "#{compile_cache_dir}" "#{compile_env_dir}" }
      Pkgr.debug "Running #{cmd.inspect}"

      Dir.chdir(path) do
        IO.popen(cmd) do |io|
          until io.eof?
            data = io.gets
            print data
          end
        end
        raise "compile failed" unless $?.exitstatus.zero?
      end

      true
    end

    def release(path)
      buildpack_release = Mixlib::ShellOut.new("#{dir}/bin/release \"#{path}\" > #{path}/.release")
      buildpack_release.logger = Pkgr.logger
      buildpack_release.run_command
      buildpack_release.exitstatus == 0
    end

    def dir
      File.join(buildpack_cache_dir, File.basename(url, ".git"))
    end

    def exists?
      File.directory?(dir)
    end

    def setup(edge, app_home)
      exists? ? refresh(edge) : install
      replace_app_with_app_home(app_home)
    end

    def refresh(edge = true)
      return if !edge
      Dir.chdir(dir) do
        buildpack_refresh = Mixlib::ShellOut.new("git fetch origin && ( git reset --hard #{branch} || git reset --hard origin/#{branch} )")
        buildpack_refresh.logger = Pkgr.logger
        buildpack_refresh.run_command
        buildpack_refresh.error!
      end
    end

    def install
      unless exists?
        FileUtils.mkdir_p(buildpack_cache_dir)
        Dir.chdir(buildpack_cache_dir) do
          puts "-----> Fetching buildpack #{url} at #{branch}"
          buildpack_install = Mixlib::ShellOut.new("git clone '#{url}'")
          buildpack_install.logger = Pkgr.logger
          buildpack_install.run_command
          buildpack_install.error!
        end
      end
      refresh(true)
    end

    def replace_app_with_app_home(app_home)
      Dir.chdir(dir) do
        buildpack_replace = Mixlib::ShellOut.new("find . -type f -not -path '*/.git/*' -print0 | xargs -0 perl -pi -e s,/app/,#{app_home}/,g")
        buildpack_replace.logger = Pkgr.logger
        buildpack_replace.run_command
        buildpack_replace.error!
      end
    end
  end
end
