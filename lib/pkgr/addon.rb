module Pkgr
  class Addon
    attr_reader :nickname, :addons_dir
    attr_reader :config

    def initialize(nickname, addons_dir, config)
      @nickname = nickname
      @addons_dir = addons_dir
      @config = config
    end

    def name
      File.basename(url_without_branch, ".git").sub("addon-", "")
    end

    def url_without_branch
      nickname.split("#")[0]
    end

    def url
      if nickname.start_with?("http")
        url_without_branch
      else
        user, repo = nickname.split("/", 2)
        user, repo = "pkgr", user if repo.nil?
        repo = "addon-#{repo}" unless repo.start_with?("addon-")

        "https://github.com/#{user}/#{repo}"
      end
    end

    def branch
      nickname.split("#")[1] || "master"
    end

    def tarball_url
      "#{url}/archive/#{branch}.tar.gz"
    end

    def debian_dependency_name
      [
        [config.name, name].join("-"),
        "(= #{config.version}-#{config.iteration})"
      ].join(" ")
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

    def install!(src_dir)
      install_addon = Mixlib::ShellOut.new %{curl -L --max-redirs 3 --retry 5 -s '#{tarball_url}' | tar xzf - --strip-components=1 -C '#{dir}'}
      install_addon.logger = Pkgr.logger
      install_addon.run_command
      install_addon.error!

      # TODO: remove args from command once all addons use env variables
      compile_addon = Mixlib::ShellOut.new(%{#{dir}/bin/compile '#{config.name}' '#{config.version}' '#{config.iteration}' '#{src_dir}' 2>&1}, {
        :environment => {
          "APP_NAME" => config.name,
          "APP_VERSION" => config.version,
          "APP_ITERATION" => config.iteration,
          "APP_SAFE_NAME" => config.name.gsub("-", "_"),
          "APP_USER" => config.user,
          "APP_GROUP" => config.group,
          "APP_WORKSPACE" => src_dir
        }
      })
      compile_addon.logger = Pkgr.logger
      compile_addon.live_stream = LiveStream.new(STDOUT)
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

    class LiveStream
      attr_reader :stream
      def initialize(stream = STDOUT)
        @stream = stream
      end

      def <<(data)
        data.split("\n").each do |line|
          stream.puts "       #{line}"
        end
      end
    end
  end
end
