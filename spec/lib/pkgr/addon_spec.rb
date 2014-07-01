require File.dirname(__FILE__) + '/../../spec_helper'

describe Pkgr::Addon do
  let(:addons_dir) { Dir.mktmpdir }

  describe "name and url" do
    it "does not change the name if repo user set" do
      addon = Pkgr::Addon.new("crohr/addon-mysql", addons_dir)
      expect(addon.name).to eq("mysql")
      expect(addon.url).to eq("https://github.com/crohr/addon-mysql")
    end

    it "defaults to pkgr/name if no repo user set" do
      addon = Pkgr::Addon.new("addon-mysql", addons_dir)
      expect(addon.name).to eq("mysql")
      expect(addon.url).to eq("https://github.com/pkgr/addon-mysql")
    end

    it "accepts HTTP URIs" do
      addon = Pkgr::Addon.new("https://github.com/crohr/addon-mysql", addons_dir)
      expect(addon.name).to eq("mysql")
      expect(addon.url).to eq("https://github.com/crohr/addon-mysql")
    end
  end
end
