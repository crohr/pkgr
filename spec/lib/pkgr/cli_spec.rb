require File.dirname(__FILE__) + '/../../spec_helper'

describe Pkgr::CLI do
  it "should have a build command" do
    expect(Pkgr::CLI.class_options.keys).to include(:verbose)
    expect(Pkgr::CLI.class_options.keys).to include(:name)
  end
end