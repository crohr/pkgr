require 'pkgr/buildpack'
require 'pkgr/process'
require 'yaml'
require 'erb'

module Pkgr
  module Distributions
    class Debian

      attr_reader :version
      def initialize(version)
        @version = version
      end

      def templates(app_name)
        list = []

        # directories
        [
          "usr/local/bin",
          "opt/#{app_name}",
          "etc/#{app_name}/conf.d",
          "etc/default",
          "etc/init",
          "var/log/#{app_name}"
        ].each{|dir| list.push Templates::DirTemplate.new(dir) }

        # default
        list.push Templates::FileTemplate.new("etc/default/#{app_name}", File.new(File.join(data_dir, "default.erb")))
        # upstart master
        list.push Templates::FileTemplate.new("etc/init/#{app_name}.conf", data_file("upstart/master.conf.erb"))
        # executable
        list.push Templates::FileTemplate.new("usr/local/bin/#{app_name}", File.new(File.join(data_dir, "runner.erb")), mode: 0755)
        # logrotate
        list.push Templates::FileTemplate.new("etc/logrotate.d/#{app_name}", File.new(File.join(data_dir, "logrotate.erb")))

        # conf.d
        Dir.glob(File.join(data_dir, "conf.d", "*")).each do |file|
          list.push Templates::FileTemplate.new("etc/#{app_name}/conf.d/#{File.basename(file, ".erb")}", File.new(file))
        end

        list
      end

      def initializers_for(app_name, procfile_entries)
        list = []
        procfile_entries.select(&:daemon?).each do |process|
          Pkgr.debug "Adding #{process.inspect} to initialization scripts"
          list.push [process, Templates::FileTemplate.new("#{app_name}-#{process.name}.conf", data_file("upstart/process_master.conf.erb"))]
          list.push [process, Templates::FileTemplate.new("#{app_name}-#{process.name}-PROCESS_NUM.conf", data_file("upstart/process.conf.erb"))]
        end
        list
      end

      def fpm_command(build_dir, config)
        %{
          fpm -t deb -s dir  --verbose --debug --force \
          -C "#{build_dir}" \
          -n "#{config.name}" \
          --version "#{config.version}" \
          --iteration "#{config.iteration}" \
          --provides "#{config.name}" \
          --deb-user "root" \
          --deb-group "root" \
          -a "#{config.architecture}" \
          --template-scripts \
          --before-install #{preinstall_file(config)} \
          --after-install #{postinstall_file(config)} \
          #{dependencies(config.dependencies).map{|d| "-d '#{d}'"}.join(" ")} \
          .
        }
      end

      def buildpacks
        case version
        when "wheezy"
          %w{
            https://github.com/heroku/heroku-buildpack-ruby.git
            https://github.com/heroku/heroku-buildpack-nodejs.git
            https://github.com/heroku/heroku-buildpack-java.git
            https://github.com/heroku/heroku-buildpack-play.git
            https://github.com/heroku/heroku-buildpack-python.git
            https://github.com/heroku/heroku-buildpack-php.git
            https://github.com/heroku/heroku-buildpack-clojure.git
            https://github.com/kr/heroku-buildpack-go.git
            https://github.com/miyagawa/heroku-buildpack-perl.git
            https://github.com/heroku/heroku-buildpack-scala
            https://github.com/igrigorik/heroku-buildpack-dart.git
            https://github.com/rhy-jot/buildpack-nginx.git
            https://github.com/Kloadut/heroku-buildpack-static-apache.git
          }.map{|url| Buildpack.new(url)}
        end
      end

      def requirements
        %w{
          libssl0.9.8
          curl
        }
      end

      def preinstall_file(config)
        @preinstall_file ||= begin
          source = File.join(data_dir, "hooks", "preinstall.sh")
          file = Tempfile.new("preinstall")
          file.write ERB.new(File.read(source)).result(config.sesame)
          file.rewind
          file.path
        end
      end

      def postinstall_file(config)
        @postinstall_file ||= begin
          source = File.join(data_dir, "hooks", "postinstall.sh")
          file = Tempfile.new("postinstall")
          file.write ERB.new(File.read(source)).result(config.sesame)
          file.rewind
          file.path
        end
      end

      def dependencies(other_dependencies = nil)
        other_dependencies ||= []
        deps = YAML.load_file(File.join(data_dir, "dependencies.yml"))
        deps["default"] | deps[version] | other_dependencies
      end

      def data_file(name)
        File.new(File.join(data_dir, name))
      end

      def data_dir
        File.join(Pkgr.data_dir, "distributions", "debian")
      end
    end
  end
end