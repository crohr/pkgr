require 'pkgr/templates/file_template'
require 'pkgr/templates/dir_template'
require 'pkgr/distributions/debian'


module Pkgr
  module Distributions
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