require File.dirname(__FILE__) + '/../../spec_helper'
require 'fileutils'

describe Pkgr::Buildpack do
  it "initializes with a url" do
    buildpack = Pkgr::Buildpack.new("http://some/url")
    buildpack.url.should == "http://some/url"
  end


  describe "with ruby buildpack" do
    let(:buildpack) { Pkgr::Buildpack.new("https://github.com/heroku/heroku-buildpack-ruby.git") }
    let(:path) { Dir.mktmpdir }

    before do
      buildpack.setup
      system("tar xzf #{fixture("my-app.tar.gz")} -C #{path}")
    end

    after do
      FileUtils.rm_rf path
    end

    it "can detect a ruby app" do
      buildpack.detect(path).should be_true
    end

    it "can compile a ruby app" do
      cache_dir = FileUtils.mkdir_p(File.join(path, ".git/cache"))
      buildpack.compile(path, cache_dir).should be_true
    end
  end
end