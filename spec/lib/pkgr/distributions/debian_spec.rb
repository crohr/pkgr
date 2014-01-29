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
end