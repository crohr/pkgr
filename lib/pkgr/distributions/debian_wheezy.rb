require "pkgr/distributions/debian"

module Pkgr
  module Distributions
    class DebianWheezy < Debian
      def codename
        "wheezy"
      end
    end
  end
end
