require 'pkgr/distribution/debian'

module Pkgr
  module Distribution
    def current
      if File.exist?("/etc/debian_version")
        distro = File.read("/etc/debian_version").split("/")[0]
        Debian.new(distro)
      else
        raise "Don't know about the current distribution you're on"
      end
    end
    module_function :current
  end
end