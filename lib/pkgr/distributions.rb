require 'pkgr/templates/file_template'
require 'pkgr/templates/dir_template'
require 'pkgr/distributions/debian'
require 'facter'

module Pkgr
  module Distributions
    def current
      osfamily = Facter.value('osfamily')
      klass = const_get(osfamily)
      klass.new([Facter.value('operatingsystem'), Facter.value('lsbdistcodename')].join("-").downcase)
    rescue NameError => e
      raise Errors::UnknownDistribution, "Don't know about the current distribution you're on: #{osfamily.inspect}"
    end
    module_function :current
  end
end