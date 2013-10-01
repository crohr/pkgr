require 'fileutils'

module Pkgr
  class Buildpack
    class << self
      attr_writer :buildpack_cache_dir

      def buildpack_cache_dir
        @buildpack_cache_dir ||= File.expand_path("~/.pkgr/buildpacks").tap do |dir|
          FileUtils.mkdir_p(dir)
        end
      end
    end

    attr_reader :url, :banner

    def initialize(url)
      @url = url
    end

    def buildpack_cache_dir
      self.class.buildpack_cache_dir
    end

    def detect(path)
      buildpack_detect = Mixlib::ShellOut.new("#{dir}/bin/detect \"#{path}\"")
      buildpack_detect.run_command
      @banner = buildpack_detect.stdout.chomp
      buildpack_detect.exitstatus == 0
    end

    def compile(path, compile_cache_dir)
      Dir.chdir(path) do
        IO.popen(%{ env -i PATH="$PATH" #{dir}/bin/compile "#{path}" "#{compile_cache_dir}" }) do |io|
          until io.eof?
            data = io.gets
            data.gsub!(/^-----> /, "  + ")
            data.gsub!(/^       /, "      ")
            data.gsub!(/^\s+\!\s+$/, "")
            data.gsub!(/^\s+\!\s+/, "  ! ")
            data.gsub!(/^\s+$/, "")
            print data
          end
        end
        raise "compile failed" unless $?.exitstatus.zero?
      end

      true
    end

    def release(path, compile_cache_dir)
      buildpack_release = Mixlib::ShellOut.new("#{dir}/bin/release \"#{path}\" \"#{compile_cache_dir}\" > #{path}/.release")
      buildpack_release.run_command
      buildpack_release.exitstatus == 0
    end

    def dir
      File.join(buildpack_cache_dir, File.basename(url, ".git"))
    end

    def exists?
      File.directory?(dir)
    end

    def setup
      exists? ? refresh : install
    end

    def refresh
      Dir.chdir(dir) do
        buildpack_refresh = Mixlib::ShellOut.new("git fetch origin && git reset --hard origin/master")
        buildpack_refresh.run_command
      end
    end

    def install
      Dir.chdir(buildpack_cache_dir) do
        buildpack_install = Mixlib::ShellOut.new("git clone \"#{url}\"")
        buildpack_install.run_command
      end
    end
  end
end