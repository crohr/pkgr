require 'pkgr/version'
require 'pkgr/cli'
require 'pkgr/dispatcher'
require 'mixlib/log'

module Pkgr
  extend Mixlib::Log

  module Errors
    class Base < StandardError; end
    class UnknownAppType < Base; end
  end
end
