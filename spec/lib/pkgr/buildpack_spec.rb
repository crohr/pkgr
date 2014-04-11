require File.dirname(__FILE__) + '/../../spec_helper'
require 'fileutils'

describe Pkgr::Buildpack do
  it "initializes with a url" do
    buildpack = Pkgr::Buildpack.new("http://some/url")
    buildpack.url.should == "http://some/url"
  end


  describe ".buildpacks_cache_dir" do
    after do
      Pkgr::Buildpack.buildpacks_cache_dir = nil
    end

    it "should have a default buildpacks cache directory" do
      expect(Pkgr::Buildpack.buildpacks_cache_dir).to eq(File.expand_path("~/.pkgr/buildpacks"))
      expect(File.directory?(Pkgr::Buildpack.buildpacks_cache_dir)).to be_true
    end

    it "should overwrite the default buildpacks cache directory" do
      dir = Dir.mktmpdir
      Pkgr::Buildpack.buildpacks_cache_dir = dir
      expect(Pkgr::Buildpack.buildpacks_cache_dir).to eq(dir)
    end
  end
end