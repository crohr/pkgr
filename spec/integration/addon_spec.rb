require File.dirname(__FILE__) + '/../spec_helper'

describe "Addon" do
  let(:addons_dir) { Dir.mktmpdir }

  it "downloads and compiles the addon" do
    addon = Pkgr::Addon.new("mysql", addons_dir)
    addon.install!("blank-sinatra-app")

    expect(File.read(File.join(addons_dir, "mysql", "debian", "templates"))).to include("blank-sinatra-app")
    expect(addon.debtemplates.read).to include("blank-sinatra-app")
  end
end
