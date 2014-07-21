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

  describe "#add_addon" do
    let(:addons_dir) { Dir.mktmpdir }
    let(:addon) { Pkgr::Addon.new("mysql", addons_dir, config) }

    before do
      skip "addons are no longer added to main debconf file"
      FileUtils.cp_r(fixture("addon-mysql"), File.join(addons_dir, "mysql"))
    end

    it "adds the addon's debconf templates to the global package templates" do
      distribution.add_addon(addon)
      expect(distribution.debtemplates.read).to include(File.read(fixture("addon-mysql/debian/templates")))
    end

    it "appends the debconf templates if multiple addons" do
      empty_addon = Pkgr::Addon.new("redis", addons_dir, config)
      distribution.add_addon(addon)
      distribution.add_addon(empty_addon)
      expect(distribution.debtemplates.read).to include(File.read(fixture("addon-mysql/debian/templates")))
    end

    it "adds the addon's debconf config to the global package config" do
      distribution.add_addon(addon)
      expect(distribution.debconfig.read).to include(File.read(fixture("addon-mysql/debian/config")))
    end

    it "appends the debconf config if multiple addons" do
      empty_addon = Pkgr::Addon.new("redis", addons_dir, config)
      distribution.add_addon(addon)
      distribution.add_addon(empty_addon)
      expect(distribution.debconfig.read).to include(File.read(fixture("addon-mysql/debian/config")))
    end
  end
end
