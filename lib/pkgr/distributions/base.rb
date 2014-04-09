require 'pkgr/buildpack'
require 'pkgr/env'
require 'yaml'

module Pkgr
  module Distributions
    class Base
      # Must be overwritten by subclasses.
      def codename
        raise NotImplementedError, "codename must be set"
      end # def codename

      # Must be overwritten by subclasses.
      def osfamily
        raise NotImplementedError, "osfamily must be set"
      end # def osfamily

      def slug
        [osfamily, codename].join("-")
      end # def slug

      # Must be overwritten by subclasses.
      def default_buildpack_list
        []
      end # def default_buildpack_list

      def buildpacks(config)
        custom_buildpack_uri = config.buildpack
        if custom_buildpack_uri
          uuid = Digest::SHA1.hexdigest(custom_buildpack_uri)
          [Buildpack.new(custom_buildpack_uri, :custom, config.env)]
        else
          load_buildpack_list(config)
        end
      end # def buildpacks

      def dependencies(other_dependencies = nil)
        deps = YAML.load_file(File.join(data_dir, "dependencies.yml"))
        (deps["default"] || []) | (deps[codename] || []) | (other_dependencies || [])
      end # def dependencies

      def build_dependencies(other_dependencies = nil)
        deps = YAML.load_file(File.join(data_dir, "build_dependencies.yml"))
        (deps["default"] || []) | (deps[codename] || []) | (other_dependencies || [])
      end # def build_dependencies

      protected

      def load_buildpack_list(config)
        file = config.buildpack_list || default_buildpack_list
        return [] if file.nil?

        File.read(file).split("\n").map do |line|
          url, *raw_env = line.split(",")
          buildpack_env = (config.env || Env.new).merge(Env.new(raw_env))
          Buildpack.new(url, :builtin, buildpack_env)
        end
      end # def load_buildpack_list

    end # class Base
  end # module Distributions
end # module Pkgr

require 'pkgr/distributions/debian'
