module Pkgr
  class Env
    attr_reader :env

    def initialize(env)
      @env = env || []
    end

    def present?
      create_env_hash_from_string.length > 0
    end

    def variables
      create_env_hash_from_string
    end

    private

    def create_env_hash_from_string
      return {} if env == []

      env.inject({}) do |h, var|
        name, value = var.split('=')
        h[name.strip] = value.strip
        h
      end
    end
  end
end
