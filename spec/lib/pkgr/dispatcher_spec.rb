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
      dispatcher.app_version.should == "1.0.0"
    end

    it "should find the current version based on git-describe" do
      within_git_repo do |dir|
        dispatcher = Pkgr::Dispatcher.new(dir)
        dispatcher.app_version.should == "0.0.1"
      end
    end

    it "should default to version 0.0.0 if no git tag found, and no version given" do
      dispatcher = Pkgr::Dispatcher.new("path/to/dir")
      dispatcher.app_version.should == Pkgr::Dispatcher::DEFAULT_APP_VERSION
    end
  end

  describe "#call" do
    let(:dispatcher) { Pkgr::Dispatcher.new("path/to/dir") }

    it "launches the builder if local execution" do
      pending
      dispatcher.stub(:remote? => false)
      builder = dispatcher.call
      builder.should be_a(Pkgr::Builder)
      builder.tarball.should == dispatcher.app_tarball
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