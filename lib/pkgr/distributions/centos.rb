require "pkgr/distributions/redhat"

module Pkgr
  module Distributions
    # Contains the various components required to make a packaged app integrate well with a CentOS system.
    class Centos < Redhat
      def runner
        # in truth it is 0.6.5, but it also works with 1.5 templates.
        # maybe adopt the same structure as pleaserun, with defaults, etc.
        @runner ||= Runner.new("upstart", "1.5")
      end
    end
  end
end
