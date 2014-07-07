module Pkgr
  class Addon
    attr_reader :nickname, :addons_dir

    def initialize(nickname, addons_dir)
      @nickname = nickname
      @addons_dir = addons_dir
    end

    def name
      File.basename(nickname, ".git").sub("addon-", "")
    end

    def url
      if nickname.start_with?("http")
        nickname
      else
        user, repo = nickname.split("/", 2)
        user, repo = "pkgr", user if repo.nil?
        repo = "addon-#{repo}" unless repo.start_with?("addon-")

        "https://github.com/#{user}/#{repo}"
      end
    end

    def tarball_url
      "#{url}/archive/master.tar.gz"
    end

    def debtemplates
      debtemplates_file = File.join(dir, "debian", "templates")
      if File.exists?(debtemplates_file)
        File.new(debtemplates_file)
      else
        StringIO.new
      end
    end

    def debconfig
      debconfig_file = File.join(dir, "debian", "config")
      if File.exists?(debconfig_file)
        File.new(debconfig_file)
      else
        StringIO.new
      end
    end

    def install!(package_name, src_dir)
      install_addon = Mixlib::ShellOut.new %{curl -L --max-redirs 3 --retry 5 -s '#{tarball_url}' | tar xzf - --strip-components=1 -C '#{dir}'}
      install_addon.logger = Pkgr.logger
      install_addon.run_command
      install_addon.error!

      compile_addon = Mixlib::ShellOut.new %{#{dir}/bin/compile '#{package_name}' '#{src_dir}'}
      compile_addon.logger = Pkgr.logger
      compile_addon.run_command
      compile_addon.error!
    end

    def dir
      @dir ||= begin
        directory = File.join(addons_dir, File.basename(name))
        FileUtils.mkdir_p(directory)
        directory
      end
    end
  end
end
