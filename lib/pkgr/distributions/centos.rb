require "pkgr/distributions/redhat"

module Pkgr
  module Distributions
    # Contains the various components required to make a packaged app integrate well with a CentOS system.
    class Centos < Redhat
      def runner
        Runner.new("upstart", "1.5")
      end
    end
  end
end
