require "pkgr/distributions/debian"

module Pkgr
  module Distributions
    class DebianSqueeze < Debian
      def codename
        "squeeze"
      end
    end
  end
end
