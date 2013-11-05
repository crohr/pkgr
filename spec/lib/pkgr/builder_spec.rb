require File.dirname(__FILE__) + '/../../spec_helper'

describe Pkgr::Builder do
  let(:config) { Pkgr::Config.new(
    :name => "my-app",
    :version => "0.0.1",
    :iteration => Time.now.strftime("%Y%m%d%H%M%S")
  ) }

  it "accepts a tarball and config object" do
    builder = Pkgr::Builder.new("path/to/tarball.tgz", config)
    expect(builder.tarball).to eq("path/to/tarball.tgz")
    expect(builder.config).to eq(config)
  end

  describe "#check" do
    let(:distribution) { double("distribution", :requirements => ["doesnotexist"]) }
    let(:builder) { Pkgr::Builder.new("path/to/tarball.tgz", config).tap{|b| b.stub(:distribution => distribution)} }

    it "asks the distribution to check for missing dependencies" do
      distribution.should_receive(:check).with(builder.config)
      expect{ builder.check }.to_not raise_error
    end
  end

  describe "#setup" do
    let(:builder) { Pkgr::Builder.new("path/to/tarball.tgz", config) }

    it "creates the build hierarchy" do
      builder.stub(:distribution => double(:distribution, :templates => [
        Pkgr::Templates::DirTemplate.new("opt/my-app"),
        Pkgr::Templates::FileTemplate.new("usr/local/bin/my-app", StringIO.new("some content")),
        Pkgr::Templates::FileTemplate.new("etc/default/my-app", File.new(fixture("default.erb")))
      ]))

      builder.setup
      expect(Dir.glob(File.join(builder.build_dir, '*')).map{|dir| File.basename(dir)}.sort).to eq(["etc", "opt", "usr"])
    end
  end

  describe "#extract" do
    let(:expected_app_files) { %w{
        app config config.ru db doc Gemfile Gemfile.lock lib log Procfile public Rakefile README.md script vendor
    }.sort }

    it "fails if the given tarball does not exist" do
      builder = Pkgr::Builder.new("path/to/tarball.tgz", config)
      FileUtils.mkdir_p(builder.source_dir)

      expect{ builder.extract }.to raise_error(Mixlib::ShellOut::ShellCommandFailed)
    end

    it "should extract the given tarball file to the source directory" do
      builder = Pkgr::Builder.new(fixture("my-app.tar.gz"), config)
      FileUtils.mkdir_p(builder.source_dir)

      builder.extract

      expect(Dir.glob(File.join(builder.source_dir, "*")).map{|dir| File.basename(dir)}.sort).to eq(expected_app_files)
    end

    it "should extract the given stdin to the source directory" do
      cmd = "cat #{fixture("my-app.tar.gz")}"
      IO.popen(cmd) {|f|
        $stdin = f
        builder = Pkgr::Builder.new("-", config)
        FileUtils.mkdir_p(builder.source_dir)

        builder.extract
        expect(Dir.glob(File.join(builder.source_dir, "*")).map{|dir| File.basename(dir)}.sort).to eq(expected_app_files)
      }
    end
  end

  describe "#update_config" do
    it "does not change the config if no .pkgr.yml found at the root of the source directory" do
      builder = Pkgr::Builder.new(fixture("my-app.tar.gz"), config)
      config = builder.config
      builder.update_config
      expect(builder.config).to eq(config)
    end

    it "updates the config if a .pkgr.yml file is present" do
      dir = Dir.mktmpdir
      system "tar xzf #{fixture("my-app.tar.gz")} -C #{dir}"
      FileUtils.cp fixture("pkgr.yml"), File.join(dir, ".pkgr.yml")

      builder = Pkgr::Builder.new("path/to/tarball.tgz", config)
      builder.stub(:source_dir => dir)

      config = builder.config
      builder.update_config
      expect(builder.config).to_not eq(config)

      expect(builder.config.name).to eq("my-app")
      expect(builder.config.user).to eq("git")
    end
  end

  describe "#compile" do
    let(:builder) { Pkgr::Builder.new("path/to/tarball.tgz", config) }
    let(:distribution) { Pkgr::Distributions::Debian.new("ubuntu-precise") }

    it "has a list of buildpacks" do
      builder.stub(:distribution => distribution)
      expect(builder.buildpacks).to_not be_empty
    end

    it "raises an error if it can't find a proper buildpack" do
      builder.stub(:buildpack_for_app => nil)
      expect{ builder.compile }.to raise_error(Pkgr::Errors::UnknownAppType)
    end

    it "raises an error if something occurs during buildpack compilation" do
      buildpack = double(Pkgr::Buildpack, :banner => "Ruby/Rails")
      builder.stub(:buildpack_for_app => buildpack)
      buildpack.should_receive(:compile).with(builder.source_dir, builder.compile_cache_dir).and_raise(Pkgr::Errors::Base)

      expect{ builder.compile }.to raise_error(Pkgr::Errors::Base)
    end

    it "raises an error if something occurs during buildpack release" do
      buildpack = double(Pkgr::Buildpack, :banner => "Ruby/Rails", :compile => true)
      builder.stub(:buildpack_for_app => buildpack)
      buildpack.should_receive(:release).with(builder.source_dir, builder.compile_cache_dir).and_raise(Pkgr::Errors::Base)

      expect{ builder.compile }.to raise_error(Pkgr::Errors::Base)
    end

    it "succeeds if everything went well" do
      buildpack = double(Pkgr::Buildpack, :banner => "Ruby/Rails", :compile => true, :release => true)
      builder.stub(:buildpack_for_app => buildpack)

      expect{ builder.compile }.to_not raise_error
    end
  end

  describe "#write_env and #write_init" do
    let(:builder) { Pkgr::Builder.new(fixture("my-app.tar.gz"), config) }
    let(:distribution) { Pkgr::Distributions::Debian.new("wheezy") }

    before do
      builder.stub(:distribution => distribution)
      builder.setup
      FileUtils.cp fixture(".release"), builder.source_dir
      FileUtils.cp fixture("Procfile"), builder.source_dir
    end

    after do
      builder.teardown
    end

    it "should write the expected process stubs" do
      expect{ builder.write_env }.to_not raise_error
      expect(Dir.glob(File.join(builder.proc_dir, "*")).map{|file| File.basename(file)}.sort).to eq([
        "console",
        "rake",
        "redis",
        "web",
        "worker"
      ])
      expect(File.read(File.join(builder.proc_dir, "web"))).to eq("bundle exec unicorn $@")
    end

    it "should write the expected init files" do
      expect{ builder.write_init }.to_not raise_error
      expect(Dir.glob(File.join(builder.build_dir, "etc/init", "*")).map{|file| File.basename(file)}.sort).to eq([
        "my-app.conf"
      ])

      expect(Dir.glob(File.join(builder.scaling_dir, "*")).map{|file| File.basename(file)}.sort).to eq([
        "my-app-web-PROCESS_NUM.conf",
        "my-app-web.conf",
        "my-app-worker-PROCESS_NUM.conf",
        "my-app-worker.conf",
      ])
    end
  end

  describe "#package" do
    let(:builder) { Pkgr::Builder.new("path/to/tarball.tgz", config) }

    before do
      builder.stub(:distribution => Pkgr::Distributions::Debian.new("wheezy"))
      builder.setup
    end

    after do
      builder.teardown
    end

    it "builds the proper fpm command" do
      command = builder.fpm_command.strip.squeeze(" ")
      expect(command).to include("fpm -t deb -s dir --verbose --force -C \"#{builder.build_dir}\" -n \"my-app\" --version \"0.0.1\" --iteration \"#{config.iteration}\" --url \"#{config.homepage}\" --provides \"my-app\"")
    end

    it "launches fpm on build dir" do
      fpm_command = "ls"
      builder.stub(:fpm_command => fpm_command)

      expect{ builder.package }.to_not raise_error
    end
  end
end