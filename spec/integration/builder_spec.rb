require File.dirname(__FILE__) + '/../spec_helper'

describe "Builder" do
  it "builds the full package [Rails app]" do
    Pkgr.level = Logger::INFO
    config = Pkgr::Config.new(
      :name => "my-app",
      :version => "0.0.1",
      :iteration => "1234",
      :env => ["CURL_TIMEOUT=250"],
      :auto => true,
      :compile_cache_dir => "/tmp/cache-for-ruby-app-integration-test")

    builder = Pkgr::Builder.new(fixture("my-app.tar.gz"), config)
    expect{ builder.call }.to_not raise_error
  end
end
