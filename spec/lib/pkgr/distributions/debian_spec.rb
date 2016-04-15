require File.dirname(__FILE__) + '/../../../spec_helper'

describe Pkgr::Distributions::Debian do
  let(:config) { Pkgr::Config.new }
  let(:distribution) { Pkgr::Distributions::Debian.new("7.4", config) }

  it "has a default debconfig by default" do
    expect(distribution.debconfig.read).to eq("#!/bin/bash\n")
  end

  it "has a default debtemplates by default" do
    expect(distribution.debtemplates.read).to eq("")
  end

  describe "dependencies" do
    it "has default dependencies" do
      expect(distribution.dependencies).to_not be_empty
    end

    it "can skip default dependencies" do
      config.default_dependencies = false
      expect(distribution.dependencies).to be_empty
    end
  end

  it "has file and dir templates" do
    config.name = "my-app"
    config.home = "/opt/my-app"
    expect(distribution.templates).to_not be_empty
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
    it "has a list of default buildpacks" do
      list = distribution.buildpacks
      expect(list).to_not be_empty
      expect(list.all?{|b| b.is_a?(Pkgr::Buildpack)}).to eq(true)
    end
  end

  describe "buildpack list" do
    ["6.0.4", "7.4"].each do |release|
      it "debian #{release} has a list of default buildpacks" do
        distribution = Pkgr::Distributions::Debian.new(release, config)
        expect(distribution.buildpacks).to_not be_empty
      end
    end
  end
end
