require File.dirname(__FILE__) + '/../spec_helper'

describe "Builder" do
  it "builds the full package" do
    config = Pkgr::Config.new(:app_name => "my-app", :app_version => "0.0.1", :app_iteration => "1234")
    builder = Pkgr::Builder.new(fixture("my-app.tar.gz"), config)
    expect{ builder.call }.to_not raise_error
  end
end