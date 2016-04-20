module Pkgr
  module Distributions
    class Redhat < Fedora
      def runner
        @runner ||= case release
        when /^6/
          Runner.new("upstart", "1.5", "initctl")
        else
          # newer releases default to using systemd as the init system
          Runner.new("systemd", "default", "systemctl")
        end
      end

      def templates
        if ["centos-6", "redhat-6"].include?(slug)
          list = super
          list.push Templates::DirTemplate.new("etc/init")
          list
        else
          super
        end
      end

    end
  end
end
