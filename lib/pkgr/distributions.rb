require 'pkgr/templates/file_template'
require 'pkgr/templates/dir_template'
require 'pkgr/distributions/debian'
require 'facter'

module Pkgr
  module Distributions
    def current
      os = Facter.value('operatingsystem').capitalize
      codename = Facter.value('lsbdistcodename').capitalize

      klass = const_get("#{os}#{codename}")
      klass.new
    rescue NameError => e
      raise Errors::UnknownDistribution, "Don't know about the current distribution you're on: #{os}-#{codename}"
    end
    module_function :current
  end
end
