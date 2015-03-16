require 'pathname'

module Pkgr
  class Addon
    def initialize(nickname)
      @nickname = nickname
    end

    def name
      File.basename(url).sub("addon-", "")
    end

    def install!(dir, shell = Command.new(Pkgr.logger))
      addon_dir = "#{dir}/#{name}"
      FileUtils.mkdir_p addon_dir
      puts "-----> [wizard] adding #{name} wizard (#{url}##{branch})"
      if url.is_a?(Pathname)
        shell.run! "cp -r #{url}/* #{addon_dir}"
      else
        shell.run! "curl -L --max-redirs 3 --retry 5 -s '#{tarball_url}' | tar xzf - --strip-components=1 -C '#{addon_dir}'"
      end
    end

  private

    def url
      @url ||= begin
        if @nickname.is_a?(Pathname)
          @nickname
        elsif @nickname.start_with?("http")
          url_without_branch
        else
          user, repo = @nickname.split("/", 2)
          user, repo = "pkgr", user if repo.nil?
          repo = "addon-#{repo}" unless repo.start_with?("addon-")

          "https://github.com/#{user}/#{repo}"
        end
      end
    end

    def branch
      return if url.is_a?(Pathname)
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
