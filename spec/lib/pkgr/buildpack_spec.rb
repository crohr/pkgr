require File.dirname(__FILE__) + '/../../spec_helper'
require 'fileutils'

describe Pkgr::Buildpack do
  after do
    Pkgr::Buildpack.buildpacks_cache_dir = nil
  end

  it "initializes with a url" do
    buildpack = Pkgr::Buildpack.new("http://some/url")
    buildpack.url.should == "http://some/url"
  end

  describe "#install" do
    before do
      Pkgr::Buildpack.buildpacks_cache_dir = Dir.mktmpdir
    end

    it "works with branches" do
      buildpack = Pkgr::Buildpack.new("https://github.com/pkgr/heroku-buildpack-ruby.git#universal")
      expect do
        buildpack.install
      end.to_not raise_error
      Dir.chdir(buildpack.dir) do
        expect(%x{git diff origin/universal}).to eq("")
      end
    end

    it "works with tags" do
      buildpack = Pkgr::Buildpack.new("https://github.com/heroku/heroku-buildpack-nodejs.git#v58")
      expect do
        buildpack.install
      end.to_not raise_error
      Dir.chdir(buildpack.dir) do
        expect(%x{git log HEAD --oneline}).to include("97a5856")
      end
    end
  end

  describe ".buildpacks_cache_dir" do
    it "should have a default buildpacks cache directory" do
      expect(Pkgr::Buildpack.buildpacks_cache_dir).to eq(File.expand_path("~/.pkgr/buildpacks"))
      expect(File.directory?(Pkgr::Buildpack.buildpacks_cache_dir)).to eq(true)
    end

    it "should overwrite the default buildpacks cache directory" do
      dir = Dir.mktmpdir
      Pkgr::Buildpack.buildpacks_cache_dir = dir
      expect(Pkgr::Buildpack.buildpacks_cache_dir).to eq(dir)
    end
  end
end
