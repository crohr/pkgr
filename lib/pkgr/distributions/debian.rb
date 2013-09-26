require 'pkgr/buildpack'

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
          "etc/default"
        ].each{|dir| list.push Templates::DirTemplate.new(dir) }

        # default
        list.push Templates::FileTemplate.new("etc/default/#{app_name}", File.new(File.join(data_dir, "default.erb")))

        # conf.d
        Dir.glob(File.join(data_dir, "conf.d", "*")).each do |file|
          list.push Templates::FileTemplate.new("etc/#{app_name}/conf.d/#{File.basename(file, ".erb")}", File.new(file))
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
          --deb-user "#{config.user}" \
          --deb-group "#{config.group}" \
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

      def data_dir
        File.join(Pkgr.data_dir, "distributions", "debian")
      end
    end
  end
end