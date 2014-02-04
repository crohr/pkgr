require "pkgr/distributions/debian_wheezy"

module Pkgr
  module Distributions
    class UbuntuPrecise < DebianWheezy
      def codename
        "precise"
      end

      def osfamily
        "ubuntu"
      end
    end
  end
end
