require File.dirname(__FILE__) + '/../../spec_helper'

describe Pkgr::Config do
  let(:config) { Pkgr::Config.new(:version => "0.0.1", :name => "my-app", :iteration => "1234") }

  it "is valid" do
    expect(config).to be_valid
  end

  it "is no valid if no name given" do
    config.name = ""
    expect(config).to_not be_valid
    expect(config.errors).to include("name can't be blank")
  end

  it "exports to cli arguments" do
    config.homepage = "http://somewhere"
    config.description = "some description"
    expect(config.to_args).to include("--description \"some description\"")
    expect(config.to_args).to include("--version \"0.0.1\"")
    expect(config.to_args).to include("--name \"my-app\"")
    expect(config.to_args).to include("--user \"my-app\"")
    expect(config.to_args).to include("--group \"my-app\"")
    expect(config.to_args).to include("--architecture \"x86_64\"")
    expect(config.to_args).to include("--homepage \"http://somewhere\"")
  end
end