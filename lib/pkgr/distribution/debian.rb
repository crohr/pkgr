require 'pkgr/buildpack'

module Pkgr
  module Distribution
    class Debian
      attr_reader :version
      def initialize(version)
        @version = version
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
    end
  end
end