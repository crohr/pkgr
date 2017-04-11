require 'pkgr/env_value'

module Pkgr
  class Env
    attr_reader :variables

    def self.from_export(file)
      new(File.read(file).split("\n").map { |line| line.sub(/^export\s+/, "") })
    end

    def initialize(variables = nil)
      @variables = variables || []
      @variables.compact!
    end

    def to_s
      to_hash.map{|k, v| [k, v.quote].join("=")}.join(" ")
    end

    def present?
      create_env_hash_from_string.length > 0
    end

    def to_hash
      create_env_hash_from_string
    end

    def merge(other)
      self.class.new(self.variables + other.variables)
    end

    private
    def create_env_hash_from_string
      return {} if variables == []

      variables.inject({}) do |h, var|
        name, value = var.split('=', 2)
        h[name.strip] = EnvValue.new(value || "").strip.unquote
        h
      end
    end
  end
end
