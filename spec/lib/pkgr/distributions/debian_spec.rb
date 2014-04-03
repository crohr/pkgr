require File.dirname(__FILE__) + '/../../../spec_helper'

describe Pkgr::Distributions::Debian do
  let(:distribution) { Pkgr::Distributions::DebianWheezy.new }

  it "has file and dir templates" do
    expect(distribution.templates("my-app")).to_not be_empty
  end

  describe "#dependencies" do
    it "has the expected default dependencies" do
      expect(distribution.dependencies).to include("libmysqlclient18")
    end

    it "includes additional dependencies as well" do
      expect(distribution.dependencies(["dep1", "dep2"])).to include("libmysqlclient18", "dep1", "dep2")
    end
  end

  describe "#buildpacks" do
    let(:config) { OpenStruct.new }

    it "has a list of default buildpacks" do
      expect(distribution.buildpacks(config)).to_not be_empty
    end

    it "can take an external list of default buildpacks" do
      config.buildpack_list = fixture("buildpack-list")
      expect(distribution.buildpacks(config)).to eq([
        "https://github.com/heroku/heroku-buildpack-play.git#v121",
        "https://github.com/heroku/heroku-buildpack-python.git"
      ])
    end
  end
end