require "pkgr/distributions/debian"

module Pkgr
  module Distributions
    class DebianWheezy < Debian
      def codename
        "wheezy"
      end

      def default_buildpacks
        %w{
          https://github.com/pkgr/heroku-buildpack-ruby.git#precise
          https://github.com/heroku/heroku-buildpack-nodejs.git
          https://github.com/heroku/heroku-buildpack-java.git
          https://github.com/heroku/heroku-buildpack-play.git
          https://github.com/heroku/heroku-buildpack-python.git
          https://github.com/heroku/heroku-buildpack-clojure.git
        }
      end
    end
  end
end
