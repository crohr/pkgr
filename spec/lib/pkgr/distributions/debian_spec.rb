require File.dirname(__FILE__) + '/../../../spec_helper'

describe Pkgr::Distributions::Debian do
  let(:distribution) { Pkgr::Distributions::Debian.new("wheezy") }

  it "has file and dir templates" do
    expect(distribution.templates("my-app")).to_not be_empty
  end

  it "has the expected dependencies" do
    expect(distribution.dependencies).to include("libmysqlclient18")
  end
end