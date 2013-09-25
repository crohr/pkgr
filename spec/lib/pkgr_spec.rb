require File.dirname(__FILE__) + '/spec_helper'

describe Pkgr do
  it "should have a version" do
    Pkgr::VERSION.should_not be_nil
  end
end