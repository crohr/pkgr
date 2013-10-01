require File.dirname(__FILE__) + '/../spec_helper'

describe "Builder" do
  it "builds the full package" do
    Pkgr.level = Logger::INFO
    config = Pkgr::Config.new(:name => "my-app", :version => "0.0.1", :iteration => "1234")
    builder = Pkgr::Builder.new(fixture("my-app.tar.gz"), config)
    expect{ builder.call }.to_not raise_error
  end
end