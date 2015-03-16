module Pkgr
  class Addon
    def initialize(nickname)
      @nickname = nickname
    end

    def name
      File.basename(url_without_branch, ".git").sub("addon-", "")
    end

    def install!(dir, shell = Command.new(Pkgr.logger))
      addon_dir = "#{dir}/#{name}"
      FileUtils.mkdir_p addon_dir
      puts "-----> [wizard] adding #{name} wizard (#{url}##{branch})"
      shell.run! "curl -L --max-redirs 3 --retry 5 -s '#{tarball_url}' | tar xzf - --strip-components=1 -C '#{addon_dir}'"
    end

  private

    def url
      if @nickname.start_with?("http")
        url_without_branch
      else
        user, repo = @nickname.split("/", 2)
        user, repo = "pkgr", user if repo.nil?
        repo = "addon-#{repo}" unless repo.start_with?("addon-")

        "https://github.com/#{user}/#{repo}"
      end
    end

    def branch
      @nickname.split("#")[1] || "master"
    end

    def tarball_url
      "#{url}/archive/#{branch}.tar.gz"
    end

    def url_without_branch
      @nickname.split("#")[0].sub(/\.git$/,'')
    end
  end
end
