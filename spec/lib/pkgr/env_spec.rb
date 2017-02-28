require 'spec_helper'

require 'tempfile'

describe Pkgr::Env do
  describe 'emtpy env' do
    subject { described_class.new([]) }

    it "should not be present" do
      expect(subject).to_not be_present
    end

    it "should have an empty hash" do
      expect(subject.to_hash).to be_empty
    end
  end

  describe 'environment example' do
    subject { described_class.new(["CURL_TIMEOUT=250", "BUNDLE_WITHOUT=development test", "PATH=\"$PATH\""]) }
    it "should be present" do
      expect(subject).to be_present
    end

    it "should have the correct hash" do
      expect(subject.to_hash).to eq({"CURL_TIMEOUT" => "250", "BUNDLE_WITHOUT" => "development test", "PATH" => "$PATH"})
      expect(subject.to_s).to eq("CURL_TIMEOUT=\"250\" BUNDLE_WITHOUT=\"development test\" PATH=\"$PATH\"")
    end
  end

  describe 'invalid input' do
    subject { described_class.new(["CURL_TIMEOUT = 250"]) }

    it "should be present" do
      expect(subject).to be_present
    end

    it "should have the correct hash" do
      expect(subject.to_hash).to eq({"CURL_TIMEOUT" => "250"})
    end
  end

  describe 'from a buildpack environment export' do
    it "populates the collection of variables" do
      export = Tempfile.new('export')
      export.write("export FOO=bar\nexport DOO=dah")
      export.rewind
      expect(described_class.from_export(export.path).to_hash).to eq({"FOO" => "bar", "DOO" => "dah"})
    end
  end
end
