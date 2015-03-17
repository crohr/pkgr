require 'pkgr/command'
require 'fileutils'

module Pkgr
  class Installer
    DEFAULT_URL = "https://github.com/pkgr/installer.git#master"

    attr_reader :url, :branch
    attr_reader :distribution

    def initialize(installer_url, distribution)
      @installer_url = installer_url
      @installer_url = DEFAULT_URL if @installer_url == true || @installer_url.nil? || @installer_url.empty?
      @url, @branch = @installer_url.split("#", 2)
      @branch ||= "master"
      @distribution = distribution
    end

    def shell
      Command.new(Pkgr.logger)
    end

    def setup
      shell.run!("git clone --depth=1 --branch=\"#{branch}\" \"#{url}\" #{installer_tmp_dir}")
      self
    end

    def call(config)
      Dir.chdir(installer_tmp_dir) do
        config.wizards.each do |addon_group|
          addon_group.each do |addon|
            addon.install! 'addons'
          end
        end

        shell.stream!(
          "./bin/compile",
          {
            "APP_NAME" => config.name,
            "APP_VERSION" => config.version,
            "APP_ITERATION" => config.iteration,
            "APP_SAFE_NAME" => config.safe_name,
            "APP_USER" => config.user,
            "APP_GROUP" => config.group,
            "APP_WORKSPACE" => config.source_dir,
            # mysql|postgres,apache2|nginx,smtp
            "APP_WIZARDS" => config.wizards.map{|addon_group| addon_group.map(&:name).join("|")}.join(",")
          }
        )
      end

      FileUtils.mv installer_tmp_dir, File.join(config.build_dir, "usr", "share", config.name, "installer")

      config.dependencies.push(*distribution.installer_dependencies)
      config
    end

    def installer_tmp_dir
      @installer_tmp_dir ||= Dir.mktmpdir
    end
  end
end
