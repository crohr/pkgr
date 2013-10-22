require File.dirname(__FILE__) + '/../../spec_helper'

describe Pkgr::Distributions do
  it "raises an error if the distribution is unknown" do
    Facter.should_receive(:value).with('osfamily').and_return("whatever")
    expect{ Pkgr::Distributions.current }.to raise_error(Pkgr::Errors::UnknownDistribution)
  end

  it "returns a debian distribution if osfamily is 'Debian'" do
    Facter.should_receive(:value).with('osfamily').ordered.and_return("Debian")
    Facter.should_receive(:value).with('operatingsystem').ordered.and_return("Ubuntu")
    Facter.should_receive(:value).with('lsbdistcodename').ordered.and_return("precise")
    current_distribution = Pkgr::Distributions.current
    expect(current_distribution).to be_a(Pkgr::Distributions::Debian)
    expect(current_distribution.version).to eq("ubuntu-precise")
  end
end
