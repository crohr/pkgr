require File.dirname(__FILE__) + '/../../spec_helper'

describe Pkgr::Addon do
  let(:addons_dir) { Dir.mktmpdir }
  let(:config) { double(:config) }

  describe "name and url" do
    it "does not change the name if repo user set" do
      addon = Pkgr::Addon.new("crohr/addon-mysql", addons_dir, config)
      expect(addon.name).to eq("mysql")
      expect(addon.url).to eq("https://github.com/crohr/addon-mysql")
    end

    it "defaults to pkgr/name if no repo user set" do
      addon = Pkgr::Addon.new("addon-mysql", addons_dir, config)
      expect(addon.name).to eq("mysql")
      expect(addon.url).to eq("https://github.com/pkgr/addon-mysql")
    end

    it "defaults to pkgr/name if no repo user set" do
      addon = Pkgr::Addon.new("mysql", addons_dir, config)
      expect(addon.name).to eq("mysql")
      expect(addon.url).to eq("https://github.com/pkgr/addon-mysql")
    end

    it "accepts HTTP URIs" do
      addon = Pkgr::Addon.new("https://github.com/crohr/addon-mysql", addons_dir, config)
      expect(addon.name).to eq("mysql")
      expect(addon.url).to eq("https://github.com/crohr/addon-mysql")
    end
  end

  describe "debtemplates" do
    let(:addon) { Pkgr::Addon.new("mysql", addons_dir, config) }
    let(:debian_dir) { File.join(addon.dir, "debian") }

    before do
      FileUtils.mkdir_p debian_dir
    end

    it "returns the templates file" do
      File.open(File.join(debian_dir, "templates"), "w+") {|f| f.puts "template" }
      expect(addon.debtemplates.read).to eq("template\n")
    end

    it "returns an empty io if debian/templates does not exist" do
      expect(addon.debtemplates.read).to eq("")
    end
  end

  describe "debconfig" do
    let(:addon) { Pkgr::Addon.new("mysql", addons_dir, config) }
    let(:debian_dir) { File.join(addon.dir, "debian") }

    before do
      FileUtils.mkdir_p debian_dir
    end

    it "returns the config file" do
      File.open(File.join(debian_dir, "config"), "w+") {|f| f.puts "config" }
      expect(addon.debconfig.read).to eq("config\n")
    end

    it "returns an empty io if debian/config does not exist" do
      expect(addon.debconfig.read).to eq("")
    end
  end
end
