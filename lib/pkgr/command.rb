require 'logger'
require 'mixlib/shellout'

module Pkgr
class Command
  class CommandFailed < RuntimeError; end

  attr_accessor :logger, :log_tag

  class << self
    attr_accessor :default_timeout
    default_timeout = 60
  end

  def initialize(logger = nil, log_tag = nil)
    @logger = logger || Logger.new(STDOUT)
    @log_tag = log_tag
  end

  def stream!(command, env = {})
    _stream(command, {env: env, fail: true, live_stream: logger})
  end

  def stream(command, env = {})
    _stream(command, {env: env, live_stream: logger})
  end

  def capture!(command, error_message, env = {})
    value = _run(command, {env: env, fail: true})
    value = yield(value) if block_given?
    value
  end

  def capture(command, env = {})
    value = _run(command, {env: env})
    value = yield(value) if block_given?
    value
  end

  def run(command, env = {})
    _run(command, {env: env})
  end

  def run!(command, env = {})
    _run(command, {env: env, fail: true})
  end

  def _stream(command, opts = {})
    env = opts[:env] || {}
    fail = !! opts[:fail]
    env_string = env.map{|(k,v)| [k,"\"#{v}\""].join("=")}.join(" ")

    logger.debug "sh(#{command})"

    IO.popen("#{env_string} #{command}") do |io|
      until io.eof?
        data = io.gets
        logger << data
      end
    end

    raise CommandFailed, "Failure during packaging" if fail && ! $?.exitstatus.zero?
  # raised when file does not exist
  rescue Errno::ENOENT, RuntimeError => e
    raise CommandFailed, e.message
  end

  def _run(command, opts = {})
    env = opts[:env] || {}
    live_stream = opts[:live_stream]
    fail = !! opts[:fail]

    cmd = Mixlib::ShellOut.new(
      command,
      environment: env,
      timeout: self.class.default_timeout
    )

    # live stream is buggy, using IO.popen instead
    # cmd.live_stream = logger if live_stream
    cmd.logger = logger
    cmd.log_level = :debug
    cmd.log_tag = log_tag if log_tag
    cmd.run_command

    cmd.error! if fail

    cmd.stdout.chomp
  rescue RuntimeError, Errno::ENOENT => e
    logger.error "Command failed: #{e.message}"

    msg = ["Command failed"]
    cmd.stdout.split("\n").each do |line|
      msg.push "STDOUT -- #{line}"
    end
    cmd.stderr.split("\n").each do |line|
      msg.push "STDERR -- #{line}"
    end
    raise CommandFailed, msg.join("\n")
  end
end
end
