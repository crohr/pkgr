require 'spec_helper'

describe Pkgr::Configuration do
  it "should laod from a YAML file" do
    props = Pkgr::Configuration.load_from(File.expand_path("../../fixtures/config1.yml", __FILE__))
    props.should == {"property1"=>true, "property2"=>false}
  end
end