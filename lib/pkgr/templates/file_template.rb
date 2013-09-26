module Pkgr
  module Templates
    class FileTemplate
      attr_reader :source, :target

      def initialize(target, source)
        @target = target
        @source = source
      end

      # Assumes that the current working directory is correct
      def install(template_binding)
        make_dir
        File.open(target, "w+") do |f|
          if source.respond_to?(:extname) && source.extname == ".erb"
            f << ERB.new(source.read).result(template_binding)
          else
            f << source.read
          end
        end
      end

      private
      def make_dir
        FileUtils.mkdir_p File.dirname(target)
      end
    end
  end
end
