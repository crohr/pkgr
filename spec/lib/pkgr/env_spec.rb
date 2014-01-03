require 'spec_helper'

describe Pkgr::Env do
  describe 'emtpy env' do
    subject { described_class.new([]) }

    its(:present?) { should be_false }
    its(:variables) { should eq({}) }
  end

  describe 'environment example' do
    subject { described_class.new(["CURL_TIMEOUT=250", "BUNDLE_WITHOUT=web"]) }
    its(:present?) { should be_true }
    its(:variables) { should eq({"CURL_TIMEOUT" => "250", "BUNDLE_WITHOUT" => "web"}) }
  end

  describe 'invalid input' do
    subject { described_class.new(["CURL_TIMEOUT = 250"]) }

    its(:present?) { should be_true }
    its(:variables) { should eq({"CURL_TIMEOUT" => "250"}) }
  end
end
