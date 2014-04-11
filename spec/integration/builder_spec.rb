require File.dirname(__FILE__) + '/../spec_helper'

describe "Builder" do
  it "builds the full package [Rails app]" do
    Pkgr.level = Logger.const_get(ENV['DEBUG'] || "DEBUG")
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

  it "correctly updates the config" do
    Pkgr.level = Logger.const_get(ENV['DEBUG'] || "DEBUG")

    Dir.chdir("/tmp") do
      system "[ -d gitlabhq ] || git clone https://github.com/crohr/gitlabhq"
    end

    Dir.chdir("/tmp/gitlabhq") do
      system "git fetch origin && git checkout -f 758ea23"
    end

    config = {
      :env => ["CURL_TIMEOUT=250"],
      :auto => true,
      :iteration => "1234",
      :force_os => "debian-wheezy"
    }

    dispatcher = Pkgr::Dispatcher.new("/tmp/gitlabhq", config)
    expect{ dispatcher.call }.to_not raise_error
  end
end
