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
      list = distribution.buildpacks(config)
      expect(list).to_not be_empty
      expect(list.all?{|b| b.is_a?(Pkgr::Buildpack)}).to be_true
    end

    it "can take an external list of default buildpacks" do
      config.buildpack_list = fixture("buildpack-list")
      list = distribution.buildpacks(config)
      expect(list.length).to eq(2)
      expect(list.all?{|b| b.is_a?(Pkgr::Buildpack)}).to be_true
      expect(list.first.env.to_hash).to eq({
        "VENDOR_URL"=>"https://path/to/vendor", "CURL_TIMEOUT"=>"123"
      })
    end

    it "prioritize buildpack specific environment variables over the global ones" do
      config.env = Pkgr::Env.new(["VENDOR_URL=http://global/path"])
      config.buildpack_list = fixture("buildpack-list")
      list = distribution.buildpacks(config)
      expect(list.first.env.to_hash["VENDOR_URL"]).to eq("https://path/to/vendor")
      expect(list.last.env.to_hash["VENDOR_URL"]).to eq("http://global/path")
    end
  end

  describe "buildpack list" do
    ["DebianWheezy", "DebianSqueeze", "UbuntuPrecise", "UbuntuLucid"].each do |distro|
      it "has a list of default buildpacks" do
        distribution = Pkgr::Distributions.const_get(distro).new
        expect(distribution.buildpacks(Pkgr::Config.new)).to_not be_empty
      end
    end
  end
end