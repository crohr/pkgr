require File.dirname(__FILE__) + '/../../spec_helper'

describe Pkgr::Distributions do
  it "raises an error if the distribution is unknown" do
    Facter.should_receive(:value).with('operatingsystem').ordered.and_return("Foo")
    Facter.should_receive(:value).with('operatingsystemrelease').ordered.and_return("bar")
    expect{ Pkgr::Distributions.current }.to raise_error(Pkgr::Errors::UnknownDistribution)
  end

  it "returns the correct ubuntu distribution" do
    Facter.should_receive(:value).with('operatingsystem').ordered.and_return("Ubuntu")
    Facter.should_receive(:value).with('operatingsystemrelease').ordered.and_return("12.04")
    current_distribution = Pkgr::Distributions.current
    expect(current_distribution).to be_a(Pkgr::Distributions::Ubuntu)
    expect(current_distribution.release).to eq("12.04")
    expect(current_distribution.runner.type).to eq("upstart")
  end

  it "forces a specific distribution" do
    distro = Pkgr::Distributions.current("debian-7.4")
    expect(distro).to be_a(Pkgr::Distributions::Debian)
    expect(distro.release).to eq("7")
  end

  it "forces a specific runner" do
    distro = Pkgr::Distributions.current("ubuntu-12.04", "sysv-lsb-3.1")
    runner = distro.runner
    expect(runner.type).to eq("sysv")
    expect(runner.version).to eq("lsb-3.1")
  end
end
