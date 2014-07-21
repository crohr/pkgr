require 'spec_helper'

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
    subject { described_class.new(["CURL_TIMEOUT=250", "BUNDLE_WITHOUT=web"]) }
    it "should be present" do
      expect(subject).to be_present
    end

    it "should have the correct hash" do
      expect(subject.to_hash).to eq({"CURL_TIMEOUT" => "250", "BUNDLE_WITHOUT" => "web"})
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
end
