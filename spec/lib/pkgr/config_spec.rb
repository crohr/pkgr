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

  it "can read from a config file" do
    config = Pkgr::Config.load_file(fixture("pkgr.yml"), "squeeze")
    expect(config.name).to eq("some-awesome-app")
    expect(config.description).to eq("An awesome description here!")
    expect(config.user).to eq("git")
    expect(config.group).to eq("git")
    expect(config.homepage).to eq("http://example.org")
    expect(config.dependencies).to eq(["mysql-server", "git-core"])
    expect(config.build_dependencies).to eq(["libmagickcore-dev", "libmagickwand-dev"])
  end

  it "can merge two config objects together" do
    config.dependencies = ["dep1", "dep2"]
    config2 = Pkgr::Config.load_file(fixture("pkgr.yml"), "squeeze")
    new_config = config.merge(config2)

    expect(new_config.name).to eq("some-awesome-app")
    expect(new_config.home).to eq("/opt/some-awesome-app")
    expect(new_config.version).to eq("0.0.1")
    expect(new_config.user).to eq("git")
    expect(new_config.dependencies).to eq(["mysql-server", "git-core"])
  end
end