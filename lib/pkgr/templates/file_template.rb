module Pkgr
  module Templates
    class FileTemplate
      attr_reader :source, :target

      def initialize(target, source, opts = {})
        @target = target
        @source = source
        @opts = opts
      end

      # Assumes that the current working directory is correct
      def install(template_binding)
        make_dir
        File.open(target, "w+") do |f|
          if source.respond_to?(:path) && File.extname(source) == ".erb"
            f << ERB.new(source.read).result(template_binding)
          else
            f << source.read
          end
        end

        FileUtils.chmod mode, target
      end

      private
      def make_dir
        FileUtils.mkdir_p File.dirname(target)
      end

      def mode
        @opts[:mode] || 0644
      end
    end
  end
end
