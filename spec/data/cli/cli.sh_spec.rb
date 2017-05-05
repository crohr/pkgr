require 'spec_helper'
require 'open3'

def debug?
  ENV['DEBUG'] == "yes"
end

class MyProcess
  attr_reader :command, :exit_status, :env, :stdout, :stderr
  attr_accessor :debug

  def initialize(command, env)
    @command = command
    @env = env
    @stdout = ""
    @stderr = ""
  end


  def call(args, opts = {})
    opts = {timeout: 0.5, environment: env}.merge(opts)

    full_command = [command, args].join(" ")
    puts full_command if debug

    cmd = Mixlib::ShellOut.new(full_command, opts)
    cmd.run_command

    @stdout = cmd.stdout.chomp
    @stderr = cmd.stderr.chomp

    puts @stdout if debug
    puts @stderr if debug
    @exit_status = cmd.exitstatus

    self
  end

  def ko?
    ! ok?
  end

  def ok?
    exit_status && exit_status.zero?
  end
end

def generate_cli(config, target)

  ["etc/default", "etc/#{config.name}/conf.d", "usr/bin", "usr/sbin", "etc/init", "etc/init.d", config.home, "var/log/#{config.name}"].each do |dir|
    FileUtils.mkdir_p(File.join(target, dir))
  end

  content = ERB.new(File.read(File.expand_path("../../../../data/cli/cli.sh.erb", __FILE__))).result(config.sesame)
  cli_filename = File.join(target, "usr", "bin", config.name)
  chroot_filename = File.join(target, "usr", "bin", "chroot")
  initctl_filename = File.join(target, "usr", "bin", "initctl")
  updaterc_filename = File.join(target, "usr", "sbin", "update-rc.d")
  chkconfig_filename = File.join(target, "usr", "sbin", "chkconfig")

  File.open(cli_filename, "w+") do |f|
    f.puts content
  end

  # fake chroot
  File.open(chroot_filename, "w+") do |f|
    f.puts "#!/bin/bash"
    f.puts "shift 5;"
    f.puts %{exec sh -c "$@"}
  end

  # fake service
  File.open(initctl_filename, "w+") do |f|
    f.puts "#!/bin/bash"
    f.puts %{if [ "$1" = "start" ]; then echo "$2 start/running, process 1234"; else echo "$2 stop/waiting"; fi}
  end

  # update-rc.d
  File.open(updaterc_filename, "w+") do |f|
    f.puts "#!/bin/bash"
    f.puts %{echo called update-rc.d with "$@"}
  end

  # chkconfig
  File.open(chkconfig_filename, "w+") do |f|
    f.puts "#!/bin/bash"
    f.puts %{echo called chkconfig with "$@"}
  end

  FileUtils.chmod 0755, [cli_filename, chroot_filename, initctl_filename, updaterc_filename, chkconfig_filename]
end

describe "bash cli" do
  let(:directory) { Dir.mktmpdir }
  let(:config) {
    Pkgr::Config.new(name: "my-app")
  }

  let(:command) {
    %{sudo -E env PATH="#{directory}/usr/bin:#{directory}/usr/sbin:$PATH" #{config.name}}
  }

  let(:process) {
    process = MyProcess.new(command, "ROOT_PATH" => directory)
    process.debug = debug?
    process
  }

  before(:each) do
    generate_cli(config, directory)
    File.open(File.join(directory, "etc", "default", config.name), "w+") do |f|
      f.puts %{export APP_HOME="#{config.home}"}
      f.puts %{export APP_NAME="#{config.name}"}
      f.puts %{export APP_GROUP="#{ENV['USER']}"}
      f.puts %{export APP_USER="#{ENV['USER']}"}
      f.puts %{export PORT=6000}
    end
    File.open(File.join(directory, config.home, "Procfile"), "w+") do |f|
      f.puts "web: echo web-process"
      f.puts "worker: echo worker-process"
      f.puts "# comment"
      f.puts "geo: echo geo-process"
    end
  end

  after(:each) do
    FileUtils.rm_rf(directory) unless debug?
  end

  context "distribution independent" do

    it "displays the usage if no args given" do
      process.call("")
      expect(process).to be_ok
      expect(process.stdout).to include("my-app run COMMAND")
    end

    it "returns the content of the logs" do
      File.open("#{directory}/var/log/#{config.name}/web-1.log", "w+") { |f| f << "some log here 1"}
      File.open("#{directory}/var/log/#{config.name}/worker-1.log", "w+") { |f| f << "some log here 2"}

      process.call("logs")
      expect(process).to be_ok
      expect(process.stdout).to include("some log here 1")
      expect(process.stdout).to include("some log here 2")
    end

    describe "config" do
      it "sets a config" do
        process.call("config:set YOH=YEAH")
        expect(process).to be_ok
        expect(process.stdout).to eq("")

        expect(File.read("#{directory}/etc/my-app/conf.d/other")).to eq("export YOH=\"YEAH\"\n")

        process.call("config:get YOH")
        expect(process).to be_ok
        expect(process.stdout).to eq("YEAH")
      end

      it "correctly sets a config with an = sign in the value" do
        process.call("config:set DATABASE_URL='mysql2://username:password@hostname/datbase_name/?reconnect=true'")
        expect(process).to be_ok
        expect(process.stdout).to eq("")

        expect(File.read("#{directory}/etc/my-app/conf.d/other")).to eq("export DATABASE_URL=\"mysql2://username:password@hostname/datbase_name/?reconnect=true\"\n")
        process.call("config:get DATABASE_URL")
        expect(process).to be_ok
        expect(process.stdout).to eq("mysql2://username:password@hostname/datbase_name/?reconnect=true")
      end

      it "allows empty values" do
        process.call("config:set YOH=YEAH")
        expect(process).to be_ok
        process.call("config:set YOH=")
        expect(process).to be_ok
        expect(File.read("#{directory}/etc/my-app/conf.d/other").strip).to eq("export YOH=\"\"")
        process.call("config:get YOH")
        expect(process).to be_ok
        expect(process.stdout).to eq("")
      end

      it "returns the full config" do
        process.call("config:set DATABASE_URL='mysql2://username:password@hostname/datbase_name/?reconnect=true'")
        process.call("config")
        expect(process).to be_ok
        expect(process.stdout).to include("HOME=#{config.home}")
        expect(process.stdout).to include("DATABASE_URL=mysql2://username:password@hostname/datbase_name/?reconnect=true")
      end

      it "does not overwrite keys with the same substring" do
        process.call("config:set SERVER_HOSTNAME=example.com")
        process.call("config:set HOST=127.0.0.1")
        process.call("config:get HOST")
        expect(process.stdout).to eq("127.0.0.1")
        process.call("config:get SERVER_HOSTNAME")
        expect(process.stdout).to eq("example.com")
      end
    end

    describe "run" do
      it "returns the result of the arbitrary command" do
        process.call("run pwd")
        expect(process).to be_ok
        expect(process.stdout).to eq(File.join(directory, config.home))
      end

      it "returns the result of a declared process" do
        web_process_filename = File.join(directory, config.home, "vendor", "pkgr", "processes", "web")
        FileUtils.mkdir_p(File.dirname(web_process_filename))
        File.open(web_process_filename, "w+") do |f|
          f.puts "#!/bin/sh"
          f << "exec "
          f << "ls"
          f << " $@"
        end
        FileUtils.chmod 0755, web_process_filename

        process.call("run web -1")
        expect(process).to be_ok
        expect(process.stdout.split("\n")).to eq(["Procfile", "vendor"])
      end
    end
  end # distribution independent

  describe "scale" do
    def create_scaling_templates(runner_type, process_name, process_command)
      type, *version = runner_type.split("-")
      target_dir = File.join(directory, config.home, "vendor", "pkgr", "scaling")
      FileUtils.mkdir_p target_dir

      runner = Pkgr::Distributions::Runner.new(type, version.join("-"))
      runner.templates(Pkgr::Process.new(process_name, process_command), config.name).each do |template|
        Dir.chdir(target_dir) do
          config.process_name = process_name
          config.process_command = process_command
          template.install(config.sesame)
        end
      end
    end

    context "upstart" do

      before do
        File.open(File.join(directory, "etc", "default", config.name), "a") do |f|
          f.puts %{export APP_RUNNER_TYPE="upstart"}
          f.puts %{export APP_RUNNER_CLI="initctl"}
        end

        create_scaling_templates("upstart-1.5", "web", "ls -al")
        create_scaling_templates("upstart-1.5", "worker", "echo worker-process")
        create_scaling_templates("upstart-1.5", "geo", "echo geo-process")
      end

      it "scales up from 0" do
        process.call("scale web=1")
        expect(process).to be_ok
        expect(process.stdout).to include("Scaling up")
        expect(process.stdout).to include("my-app-web-1 start/running")

        expect(File.exist?(File.join(directory, "etc", "init.d", "my-app"))).to be_truthy
        expect(File.exist?(File.join(directory, "etc", "init", "my-app.conf"))).to be_truthy
        expect(File.exist?(File.join(directory, "etc", "init", "my-app-web.conf"))).to be_truthy
        process_init = File.join(directory, "etc", "init", "my-app-web-1.conf")
        expect(File.exist?(process_init)).to be_truthy
        expect(File.read(process_init)).to include("PORT=6000")
      end

      it "scales up from x" do
        process.call("scale web=1")
        process.call("scale web=2")
        expect(process).to be_ok
        expect(process.stdout).to include("Scaling up")
        expect(process.stdout).to include("my-app-web-2 start/running")

        expect(File.exist?(File.join(directory, "etc", "init.d", "my-app"))).to be_truthy
        expect(File.exist?(File.join(directory, "etc", "init", "my-app.conf"))).to be_truthy
        expect(File.exist?(File.join(directory, "etc", "init", "my-app-web.conf"))).to be_truthy
        process_init = File.join(directory, "etc", "init", "my-app-web-2.conf")
        expect(File.exist?(process_init)).to be_truthy
        expect(File.read(process_init)).to include("PORT=6001")
      end

      it "does nothing if new scale equals existing scale" do
        process.call("scale web=1")
        process.call("scale web=1")
        expect(process).to be_ok
        expect(process.stdout).to include("Nothing to do")
      end

      it "does nothing if new scale equals existing scale (0)" do
        process.call("scale web=0")
        expect(process).to be_ok
        expect(process.stdout).to include("Nothing to do")
      end

      it "scales down" do
        process.call("scale web=1")
        process.call("scale web=0")
        expect(process).to be_ok
        expect(process.stdout).to include("Scaling down")
        expect(process.stdout).to include("my-app-web-1 stop/waiting")

        expect(File.exist?(File.join(directory, "etc", "init", "my-app.conf"))).to be_truthy
        expect(File.exist?(File.join(directory, "etc", "init", "my-app-web.conf"))).to be_truthy
        expect(File.exist?(File.join(directory, "etc", "init", "my-app-web-1.conf"))).to be_falsey
      end

      it "keeps track of what it's doing" do
        process.call("scale web=1")
        process.call("scale web=0")
        process.call("scale web=2")
        process.call("scale web=3")
        process.call("scale web=2")
        expect(process).to be_ok

        expect(File.exist?(File.join(directory, "etc", "init", "my-app.conf"))).to be_truthy
        expect(File.exist?(File.join(directory, "etc", "init", "my-app-web.conf"))).to be_truthy
        init1 = File.join(directory, "etc", "init", "my-app-web-1.conf")
        expect(File.exist?(init1)).to be_truthy
        init2 = File.join(directory, "etc", "init", "my-app-web-2.conf")
        expect(File.exist?(init2)).to be_truthy
        expect(File.read(init1)).to include("PORT=6000")
        expect(File.read(init2)).to include("PORT=6001")
      end

      it "properly increments ports" do
        process.call("scale web=2")
        expect(process).to be_ok
        process.call("scale geo=1")
        expect(process).to be_ok

        init1 = File.join(directory, "etc", "init", "my-app-web-1.conf")
        init2 = File.join(directory, "etc", "init", "my-app-web-2.conf")
        init3 = File.join(directory, "etc", "init", "my-app-geo-1.conf")
        expect(File.read(init1)).to include("PORT=6000")
        expect(File.read(init2)).to include("PORT=6001")
        expect(File.read(init3)).to include("PORT=6200")
      end
    end

    context "sysvinit [fedora]" do
      before(:each) do
        File.open(File.join(directory, "etc", "default", config.name), "a") do |f|
          f.puts %{export APP_RUNNER_TYPE="sysvinit"}
          f.puts %{export APP_RUNNER_CLI="chkconfig"}
        end

        create_scaling_templates("sysv-lsb-3.1", "web", "ls -al")
      end

      it "use chkconfig to enable services" do
        process.call("scale web=1")
        expect(process).to be_ok
        expect(process.stdout).to include("Scaling up")
        ["called chkconfig with my-app on", "called chkconfig with my-app-web on", "called chkconfig with my-app-web-1 on"].each do |output|
          expect(process.stdout).to include(output)
        end
      end

      it "uses chkconfig to disable services" do
        process.call("scale web=1")
        process.call("scale web=0")
        expect(process).to be_ok
        expect(process.stdout).to include("Scaling down")
        ["called chkconfig with my-app-web-1 off"].each do |output|
          expect(process.stdout).to include(output)
        end
      end
    end

    context "sysvinit [debian]" do

      before do
        File.open(File.join(directory, "etc", "default", config.name), "a") do |f|
          f.puts %{export APP_RUNNER_TYPE="sysvinit"}
          f.puts %{export APP_RUNNER_CLI="update-rc.d"}
        end

        create_scaling_templates("sysv-lsb-3.1", "web", "ls -al")
      end

      it "scales up from 0" do
        process.call("scale web=1")
        expect(process).to be_ok
        expect(process.stdout).to include("Scaling up")
        ["called update-rc.d with my-app defaults", "called update-rc.d with my-app-web defaults", "called update-rc.d with my-app-web-1 defaults"].each do |output|
          expect(process.stdout).to include(output)
        end

        expect(process.stdout).to include("my-app-web-1 started")

        expect(File.exist?(File.join(directory, "etc", "init.d", "my-app"))).to be_truthy
        expect(File.exist?(File.join(directory, "etc", "init.d", "my-app-web"))).to be_truthy
        process_init = File.join(directory, "etc", "init.d", "my-app-web-1")
        expect(File.exist?(process_init)).to be_truthy
        expect(File.read(process_init)).to include("PORT=6000")
      end

      it "scales up from x" do
        process.call("scale web=1")
        process.call("scale web=2")
        expect(process).to be_ok
        expect(process.stdout).to include("Scaling up")
        expect(process.stdout).to include("my-app-web-2 started")

        expect(File.exist?(File.join(directory, "etc", "init.d", "my-app"))).to be_truthy
        expect(File.exist?(File.join(directory, "etc", "init.d", "my-app-web"))).to be_truthy
        expect(File.exist?(File.join(directory, "etc", "init.d", "my-app-web-1"))).to be_truthy
        process_init = File.join(directory, "etc", "init.d", "my-app-web-2")
        expect(File.exist?(process_init)).to be_truthy
        expect(File.read(process_init)).to include("PORT=6001")
      end

      it "does nothing if new scale equals existing scale" do
        process.call("scale web=1")
        process.call("scale web=1")
        expect(process).to be_ok
        expect(process.stdout).to include("Nothing to do")
      end

      it "does nothing if new scale equals existing scale (0)" do
        process.call("scale web=0")
        expect(process).to be_ok
        expect(process.stdout).to include("Nothing to do")
      end

      it "scales down" do
        process.call("scale web=1")
        process.call("scale web=0")
        expect(process).to be_ok
        expect(process.stdout).to include("Scaling down")
        expect(process.stdout).to include("called update-rc.d with -f my-app-web-1 remove")

        expect(File.exist?(File.join(directory, "etc", "init.d", "my-app"))).to be_truthy
        expect(File.exist?(File.join(directory, "etc", "init.d", "my-app-web"))).to be_truthy
        expect(File.exist?(File.join(directory, "etc", "init.d", "my-app-web-1"))).to be_falsey
      end
    end
  end

end
