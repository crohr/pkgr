require "pkgr/distributions/debian"

module Pkgr
  module Distributions
    # Contains the various components required to make a packaged app integrate well with a Ubuntu system.
    class Ubuntu < Debian
      # Keep everything
      def release
        @release
      end

      def runner
        @runner ||= case release
        when /^12.04/, /^14.04/
          Runner.new("upstart", "1.5", "initctl")
        else
          Runner.new("systemd", "default", "systemctl")
        end
      end

      def templates
        list = super
        list.push Templates::DirTemplate.new("etc/init")
        list
      end
    end
  end
end
