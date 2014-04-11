require File.dirname(__FILE__) + '/../../../spec_helper'

describe Pkgr::Distributions::Debian do
  let(:distribution) { Pkgr::Distributions::Debian.new("7.4") }

  it "has file and dir templates" do
    expect(distribution.templates(double(:config, name: "my-app", home: "/opt/my-app"))).to_not be_empty
  end

  describe "#dependencies" do
    it "has the expected default dependencies" do
      expect(distribution.dependencies).to include("libmysqlclient18")
    end

    it "includes additional dependencies as well" do
      expect(distribution.dependencies(["dep1", "dep2"])).to include("libmysqlclient18", "dep1", "dep2")
    end
  end

  describe "pre/post install" do
    let(:config) { Pkgr::Config.new }

    it "has a preinstall file" do
      expect(distribution.preinstall_file(config)).to_not be_nil
    end

    it "has a postinstall file" do
      expect(distribution.postinstall_file(config)).to_not be_nil
    end
  end

  describe "initializers" do
    let(:runner) { double(:runner) }

    it "has no initializer if no process in procfile" do
      expect(distribution.initializers_for("my-app", [])).to be_empty
    end

    it "has one set of initializer per daemon process declared in the procfile" do
      processes = [
        Pkgr::Process.new("web", "rails s"),
        Pkgr::Process.new("console", "rails c"),
        Pkgr::Process.new("worker", "sidekiq")
      ]
      distribution.stub(:runner => runner)
      runner.stub(templates: [double(:template1), double(:template2)])

      templates_by_process = distribution.initializers_for("my-app", processes).group_by{|(a,b)| a}
      expect(templates_by_process.keys.map(&:name)).to eq(["web", "worker"])
      expect(templates_by_process[processes[0]].length).to eq(2)
    end
  end

  describe "#buildpacks" do
    let(:config) { OpenStruct.new }

    it "has a list of default buildpacks" do
      list = distribution.buildpacks(config)
      expect(list).to_not be_empty
      expect(list.all?{|b| b.is_a?(Pkgr::Buildpack)}).to be_true
    end

    it "can take an external list of default buildpacks" do
      config.buildpack_list = fixture("buildpack-list")
      list = distribution.buildpacks(config)
      expect(list.length).to eq(2)
      expect(list.all?{|b| b.is_a?(Pkgr::Buildpack)}).to be_true
      expect(list.first.env.to_hash).to eq({
        "VENDOR_URL"=>"https://path/to/vendor", "CURL_TIMEOUT"=>"123"
      })
    end

    it "prioritize buildpack specific environment variables over the global ones" do
      config.env = Pkgr::Env.new(["VENDOR_URL=http://global/path"])
      config.buildpack_list = fixture("buildpack-list")
      list = distribution.buildpacks(config)
      expect(list.first.env.to_hash["VENDOR_URL"]).to eq("https://path/to/vendor")
      expect(list.last.env.to_hash["VENDOR_URL"]).to eq("http://global/path")
    end
  end

  describe "buildpack list" do
    ["6.0.4", "7.4"].each do |release|
      it "debian #{release} has a list of default buildpacks" do
        distribution = Pkgr::Distributions::Debian.new(release)
        expect(distribution.buildpacks(Pkgr::Config.new)).to_not be_empty
      end
    end
  end
end