module Pkgr
  module Distributions
    class Redhat < Fedora
      def runner
        @runner ||= Runner.new("sysv", "lsb-3.1", "chkconfig")
      end
    end
  end
end

require 'pkgr/distributions/amazon'
