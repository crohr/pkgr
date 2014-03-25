require File.dirname(__FILE__) + '/../../spec_helper'
require 'tmpdir'

describe Pkgr::Dispatcher do
  def within_tmp_dir
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        yield dir
      end
    end
  end

  def within_git_repo
    within_tmp_dir do |dir|
      `git init && touch README && git add README && git commit -m "First commit" && git tag 0.0.1`
      yield dir
    end
  end

  describe "#initialize" do
    it "takes a path to the directory to package, and accepts options" do
      dispatcher = Pkgr::Dispatcher.new("path/to/dir", {opt1: "value1"})
      dispatcher.path.should == File.expand_path("path/to/dir")
    end
  end

  describe "configuration" do
    it "should default to the given version option if any" do
      dispatcher = Pkgr::Dispatcher.new("path/to/dir", {version: "1.0.0"})
      dispatcher.setup
      dispatcher.config.version.should == "1.0.0"
    end

    it "should find the current version based on git-describe" do
      within_git_repo do |dir|
        dispatcher = Pkgr::Dispatcher.new(dir)
        dispatcher.setup
        dispatcher.config.version.should == "0.0.1"
      end
    end
  end

  describe "setup" do
    let(:dir) { Dir.mktmpdir }

    it "generates a tarball if input is a directory" do
      dispatcher = Pkgr::Dispatcher.new(dir)
      dispatcher.should_receive(:tarify)
      dispatcher.setup
    end

    it "does not generate a tarball if input is a tarball" do
      dispatcher = Pkgr::Dispatcher.new(fixture("my-app.tar.gz"))
      dispatcher.should_not_receive(:tarify)
      dispatcher.setup
    end

    it "does not expand the path of options accepting file paths" do
      dispatcher = Pkgr::Dispatcher.new(dir, :compile_cache_dir => "path/to/cache", :before_precompile => "path/to/precompile_file")
      dispatcher.stub(:tarify)
      dispatcher.setup
      dispatcher.config.compile_cache_dir.should == "path/to/cache"
      dispatcher.config.before_precompile.should == "path/to/precompile_file"
    end
  end

  describe "#call" do
    let(:dispatcher) { Pkgr::Dispatcher.new("path/to/dir") }

    it "launches the builder if local execution" do
      builder = double(Pkgr::Builder)
      dispatcher.stub(:remote? => false)
      dispatcher.should_receive(:setup)
      Pkgr::Builder.should_receive(:new).with(dispatcher.path, dispatcher.config).and_return(builder)
      builder.should_receive(:call)
      dispatcher.call
    end
  end

  describe "execution" do
    it "will execute remotely if a host option was given" do
      dispatcher = Pkgr::Dispatcher.new("path/to/dir", {host: "debian-host"})
      dispatcher.should be_remote
    end

    it "will not execute remotely if no host given" do
      dispatcher = Pkgr::Dispatcher.new("path/to/dir")
      dispatcher.should_not be_remote
    end
  end
end