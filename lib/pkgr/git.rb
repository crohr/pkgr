require 'mixlib/shellout'

module Pkgr
  class Git
    attr_reader :path

    def initialize(path)
      @path = path
    end

    def latest_tag
      return nil unless valid?
      Dir.chdir(path) do
        git_describe = Mixlib::ShellOut.new("git describe --tags --abbrev=0")
        git_describe.logger = Pkgr.logger
        git_describe.run_command
        git_describe.stdout.chomp
      end
    end

    def valid?
      File.file?(File.join(path, ".git", "index"))
    end
  end
end