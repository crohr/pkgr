require File.dirname(__FILE__) + '/../../spec_helper'

describe Pkgr::Distributions do
  it "raises an error if the distribution is unknown" do
    Facter.should_receive(:value).with('operatingsystem').ordered.and_return("Foo")
    Facter.should_receive(:value).with('lsbdistcodename').ordered.and_return("bar")
    expect{ Pkgr::Distributions.current }.to raise_error(Pkgr::Errors::UnknownDistribution)
  end

  it "returns the correct debian distribution" do
    Facter.should_receive(:value).with('operatingsystem').ordered.and_return("Ubuntu")
    Facter.should_receive(:value).with('lsbdistcodename').ordered.and_return("precise")
    current_distribution = Pkgr::Distributions.current
    expect(current_distribution).to be_a(Pkgr::Distributions::UbuntuPrecise)
    expect(current_distribution.codename).to eq("wheezy")
  end
end
