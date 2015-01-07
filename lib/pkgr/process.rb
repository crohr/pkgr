module Pkgr
  class Process
    attr_reader :name, :command
    attr_accessor :scale

    def initialize(name, command, scale = 1)
      @name = name
      @command = command
      @scale = scale || 1
    end
  end
end
