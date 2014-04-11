require File.dirname(__FILE__) + '/../spec_helper'
require 'pkgr/buildpack'

describe "Builder" do
  describe "with ruby buildpack" do
    let(:buildpack) { Pkgr::Buildpack.new("https://github.com/heroku/heroku-buildpack-ruby.git") }
    let(:path) { Dir.mktmpdir }

    before do
      buildpack.stub(:replace_app_with_app_home => true)
      buildpack.setup(true, "/home/my-app")
      system("tar xzf #{fixture("my-app.tar.gz")} -C #{path}")
    end

    after do
      FileUtils.rm_rf path
    end

    it "can detect a ruby app" do
      buildpack.detect(path).should be_true
    end
  end
end
