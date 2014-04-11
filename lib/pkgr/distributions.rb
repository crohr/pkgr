require 'pkgr/templates/file_template'
require 'pkgr/templates/dir_template'
require 'pkgr/distributions/base'
require 'facter'

module Pkgr
  module Distributions
    def current(force_os = nil)
      os, release = if force_os.nil?
        [Facter.value('operatingsystem'), Facter.value('operatingsystemrelease')]
      else
        force_os.split("-")
      end

      os.downcase!

      klass = const_get(os.capitalize)
      klass.new(release)
    rescue NameError => e
      raise Errors::UnknownDistribution, "Don't know about the current distribution you're on: #{os}-#{release}"
    end
    module_function :current
  end
end
