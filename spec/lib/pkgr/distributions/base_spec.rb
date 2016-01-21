require File.dirname(__FILE__) + '/../../../spec_helper'

describe Pkgr::Distributions::Base do
  let(:config) { Pkgr::Config.new }
  let(:distribution) { Pkgr::Distributions::Base.new("7.4", config) }

  describe "pre/post install" do
    it "has a preinstall file" do
      expect(distribution.preinstall_file).to_not be_nil
    end

    it "has a postinstall file" do
      expect(distribution.postinstall_file).to_not be_nil
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
      expect(templates_by_process.keys.map(&:name)).to eq(["web", "console", "worker"])
      expect(templates_by_process[processes[0]].length).to eq(2)
    end
  end

  describe "#buildpacks" do
    it "can take an external list of default buildpacks" do
      config.buildpack_list = fixture("buildpack-list")
      type, list = distribution.buildpacks
      expect(list.length).to eq(2)
      expect(list.all?{|b| b.is_a?(Pkgr::Buildpack)}).to eq(true)
      expect(list.first.env.to_hash).to eq({
        "VENDOR_URL"=>"https://path/to/vendor", "CURL_TIMEOUT"=>"123"
      })
    end

    it "prioritize buildpack specific environment variables over the global ones" do
      config.env = Pkgr::Env.new(["VENDOR_URL=http://global/path"])
      config.buildpack_list = fixture("buildpack-list")
      type, list = distribution.buildpacks
      expect(list.first.env.to_hash["VENDOR_URL"]).to eq("https://path/to/vendor")
      expect(list.last.env.to_hash["VENDOR_URL"]).to eq("http://global/path")
    end
  end
end
