module Pkgr
  class Env
    attr_reader :variables

    def initialize(variables)
      @variables = variables || []
    end

    def to_s
      to_hash.map {|k, v| " #{k}=#{v}" }.join
    end

    def present?
      create_env_hash_from_string.length > 0
    end

    def to_hash
      create_env_hash_from_string
    end

    private

    def create_env_hash_from_string
      return {} if variables == []

      variables.inject({}) do |h, var|
        name, value = var.split('=')
        h[name.strip] = value.strip
        h
      end
    end
  end
end
