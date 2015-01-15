require File.dirname(__FILE__) + '/../../spec_helper'

describe Pkgr::CLI do
  it "should have a build command" do
    expect(Pkgr::CLI.class_options.keys).to include(:verbose)
    expect(Pkgr::CLI.class_options.keys).to include(:name)
  end

  let(:pkgr_cli) { Pkgr::CLI.new }
  let(:tmp_destination) { Dir.mktmpdir }
  let(:data_structure) { ["buildpacks", "build_dependencies",
                          "cli", "environment", "init",
                          "logrotate", "dependencies", "hooks"]
  }
  let(:copy_of_data) { Dir["#{tmp_destination}/*"].map { |f| File.basename(f) } }

  it "should have a data command" do
    expect(pkgr_cli.respond_to?(:data)).to be_truthy
    expect(pkgr_cli.data(tmp_destination)).to eq(nil)
    expect(copy_of_data).to match_array(data_structure)
  end
end
