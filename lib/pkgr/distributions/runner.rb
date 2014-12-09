module Pkgr
  module Distributions
    class Runner < Struct.new(:type, :version, :cli)

      attr_accessor :data_dir

      def sysv?
        type == "sysv"
      end

      def upstart?
        type == "upstart"
      end

      def templates(process, app_name, data_dir)
        @data_dir = data_dir
        send("templates_#{type}", process, app_name)
      end

      private
      def templates_sysv(process, app_name)
        [
          Templates::FileTemplate.new("sysv/#{app_name}", data_file("master.erb")),
          Templates::FileTemplate.new("sysv/#{app_name}-#{process.name}", data_file("process_master.erb")),
          Templates::FileTemplate.new("sysv/#{app_name}-#{process.name}-PROCESS_NUM", data_file("process.erb")),
        ]
      end

      def templates_upstart(process, app_name)
        [
          Templates::FileTemplate.new("upstart/#{app_name}", data_file("init.d.sh.erb")),
          Templates::FileTemplate.new("upstart/#{app_name}.conf", data_file("master.conf.erb")),
          Templates::FileTemplate.new("upstart/#{app_name}-#{process.name}.conf", data_file("process_master.conf.erb")),
          Templates::FileTemplate.new("upstart/#{app_name}-#{process.name}-PROCESS_NUM.conf", data_file("process.conf.erb"))
        ]
      end

      def data_file(name)
        File.new(File.join(data_dir, "init", type, version, name))
      end
    end
  end
end
