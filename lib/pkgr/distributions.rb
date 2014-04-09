require 'pkgr/templates/file_template'
require 'pkgr/templates/dir_template'
require 'pkgr/distributions/base'
require 'facter'

module Pkgr
  module Distributions
    def current(force_os = nil)
      distro = if force_os.nil?
        [Facter.value('operatingsystem'), Facter.value('lsbdistcodename')]
      else
        force_os.split("-")
      end.map(&:capitalize).join("")

      klass = const_get(distro)
      klass.new
    rescue NameError => e
      raise Errors::UnknownDistribution, "Don't know about the current distribution you're on: #{distro}"
    end
    module_function :current
  end
end
