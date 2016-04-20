require 'pkgr/version'
require 'pkgr/cli'
require 'pkgr/dispatcher'
require 'mixlib/log'

module Pkgr
  extend Mixlib::Log

  module Errors
    class Base < StandardError; end
    class UnknownAppType < Base; end
    class UnknownDistribution < Base; end
    class ConfigurationInvalid < Base; end
  end

  def data_dir=(path)
    @data_dir = path
  end
  module_function :data_dir=

  def data_dir
    @data_dir ||= File.expand_path("../../data", __FILE__)
  end
  module_function :data_dir
end
