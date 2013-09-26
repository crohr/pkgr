require File.dirname(__FILE__) + '/../../../spec_helper'

describe Pkgr::Distributions::Debian do
  let(:distribution) { Pkgr::Distributions::Debian.new("wheezy") }

  it "has the right number of templates" do
    expect(distribution.templates).to eq([])
  end
end