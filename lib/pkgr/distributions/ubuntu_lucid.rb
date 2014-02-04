require "pkgr/distributions/debian_squeeze"

module Pkgr
  module Distributions
    class UbuntuLucid < DebianSqueeze
      def codename
        "lucid"
      end

      def osfamily
        "ubuntu"
      end
    end
  end
end
