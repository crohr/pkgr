require File.dirname(__FILE__) + '/../../spec_helper'

describe Pkgr::Builder do
  let(:config) { Pkgr::Config.new(:app_name => "my-app") }

  it "accepts a tarball and config object" do
    builder = Pkgr::Builder.new("path/to/tarball.tgz", config)
    expect(builder.tarball).to eq("path/to/tarball.tgz")
    expect(builder.config).to eq(config)
  end

  describe "#setup" do
    let(:builder) { Pkgr::Builder.new("path/to/tarball.tgz", config) }

    it "creates the build hierarchy" do
      builder.setup
      expect(Dir.glob(File.join(builder.build_dir, '*')).map{|dir| File.basename(dir)}).to eq(["etc", "opt", "usr"])
    end
  end

  describe "#extract" do
    let(:expected_app_files) { %w{
        app config config.ru db doc Gemfile Gemfile.lock lib log Procfile public Rakefile README.md script vendor
    } }

    it "fails if the given tarball does not exist" do
      builder = Pkgr::Builder.new("path/to/tarball.tgz", config)
      FileUtils.mkdir_p(builder.source_dir)

      expect{ builder.extract }.to raise_error(Mixlib::ShellOut::ShellCommandFailed)
    end

    it "should extract the given tarball file to the source directory" do
      builder = Pkgr::Builder.new(fixture("my-app.tar.gz"), config)
      FileUtils.mkdir_p(builder.source_dir)

      builder.extract

      expect(Dir.glob(File.join(builder.source_dir, "*")).map{|dir| File.basename(dir)}).to eq(expected_app_files)
    end

    it "should extract the given stdin to the source directory" do
      cmd = "cat #{fixture("my-app.tar.gz")}"
      IO.popen(cmd) {|f|
        $stdin = f
        builder = Pkgr::Builder.new("-", config)
        FileUtils.mkdir_p(builder.source_dir)

        builder.extract
        expect(Dir.glob(File.join(builder.source_dir, "*")).map{|dir| File.basename(dir)}).to eq(expected_app_files)
      }
    end
  end

  describe "#compile" do
    let(:builder) { Pkgr::Builder.new("path/to/tarball.tgz", config) }
    let(:distribution) { Pkgr::Distribution::Debian.new("wheezy") }

    it "has a list of buildpacks" do
      builder.stub(:distribution => distribution)
      expect(builder.buildpacks).to_not be_empty
    end

    it "raises an error if it can't find a proper buildpack" do
      builder.stub(:buildpack_for_app => nil)
      expect{ builder.compile }.to raise_error(Pkgr::Errors::UnknownAppType)
    end

    it "raises an error if something occurs during buildpack compilation" do
      buildpack = double(Pkgr::Buildpack)
      builder.stub(:buildpack_for_app => buildpack)
      buildpack.should_receive(:compile).with(builder.source_dir, builder.compile_cache_dir).and_raise(Pkgr::Errors::Base)

      expect{ builder.compile }.to raise_error(Pkgr::Errors::Base)
    end

    it "raises an error if something occurs during buildpack release" do
      buildpack = double(Pkgr::Buildpack, :compile => true)
      builder.stub(:buildpack_for_app => buildpack)
      buildpack.should_receive(:release).with(builder.source_dir, builder.compile_cache_dir).and_raise(Pkgr::Errors::Base)

      expect{ builder.compile }.to raise_error(Pkgr::Errors::Base)
    end

    it "succeeds if everything went well" do
      buildpack = double(Pkgr::Buildpack, :compile => true, :release => true)
      builder.stub(:buildpack_for_app => buildpack)

      expect{ builder.compile }.to_not raise_error
    end
  end
end