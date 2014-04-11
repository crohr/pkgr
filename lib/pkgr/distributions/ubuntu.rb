require "pkgr/distributions/debian"

module Pkgr
  module Distributions
    # Contains the various components required to make a packaged app integrate well with a Ubuntu system.
    class Ubuntu < Debian
      def runner
        Runner.new("upstart", "1.5")
      end
    end
  end
end
