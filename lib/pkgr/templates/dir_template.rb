module Pkgr
  module Templates
    class DirTemplate
      attr_reader :target
      def initialize(target)
        @target = target
      end

      def install(template_binding)
        FileUtils.mkdir_p(target)
      end
    end
  end
end