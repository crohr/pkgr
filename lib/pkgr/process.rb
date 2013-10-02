module Pkgr
  class Process
    DAEMON_PROCESSES = ["web", "worker"]

    attr_reader :name, :command
    attr_accessor :scale

    def initialize(name, command, scale = 1)
      @name = name
      @command = command
      @scale = scale || 1
    end

    def daemon?
      DAEMON_PROCESSES.include?(name)
    end
  end
end
