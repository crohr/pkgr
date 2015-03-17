require File.dirname(__FILE__) + '/../../../spec_helper'

describe Pkgr::Distributions::Centos do
  let(:config) { Pkgr::Config.new }
  let(:distribution) { Pkgr::Distributions::Centos.new("6.5", config) }

  it "has file and dir templates" do
    config.name = "my-app"
    config.home = "/opt/my-app"
    expect(distribution.templates).to_not be_empty
  end

  describe "#dependencies" do
    it "has the expected default dependencies" do
      expect(distribution.dependencies).to include("postgresql-libs")
    end

    it "includes additional dependencies as well" do
      expect(distribution.dependencies(["dep1", "dep2"])).to include("postgresql-libs", "dep1", "dep2")
    end
  end
end
