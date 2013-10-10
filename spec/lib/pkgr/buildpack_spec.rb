require File.dirname(__FILE__) + '/../../spec_helper'
require 'fileutils'

describe Pkgr::Buildpack do
  it "initializes with a url" do
    buildpack = Pkgr::Buildpack.new("http://some/url")
    buildpack.url.should == "http://some/url"
  end


  describe "with ruby buildpack" do
    let(:buildpack) { Pkgr::Buildpack.new("https://github.com/heroku/heroku-buildpack-ruby.git") }
    let(:path) { Dir.mktmpdir }

    before do
      buildpack.stub(:replace_app_with_app_home => true)
      buildpack.setup(true, "/home/my-app")
      system("tar xzf #{fixture("my-app.tar.gz")} -C #{path}")
    end

    after do
      FileUtils.rm_rf path
    end

    it "can detect a ruby app" do
      buildpack.detect(path).should be_true
    end
  end

  it "replaces all instances of /app with app home directory" do
    buildpack_dir = Dir.mktmpdir
    example_file = "#{buildpack_dir}/example"
    File.open(example_file, "w+") do |f|
      f << <<CONTENT
# make php available on bin
mkdir -p bin
ln -s /app/php/bin/php bin/php

cat >>boot.sh <<EOF
for var in \`env|cut -f1 -d=\`; do
  echo "PassEnv \$var" >> /app/apache/conf/httpd.conf;
done
touch /app/apache/logs/error_log
touch /app/apache/logs/access_log
tail -F /app/apache/logs/error_log &
tail -F /app/apache/logs/access_log &
export LD_LIBRARY_PATH=/app/php/lib/php
export PHP_INI_SCAN_DIR=/app/www
echo "Launching apache"
exec /app/apache/bin/httpd -DNO_DETACH
EOF
CONTENT
    end
    buildpack = Pkgr::Buildpack.new("http://some/url")
    buildpack.stub(:dir => buildpack_dir)
    buildpack.replace_app_with_app_home("/opt/my-app")
    result = File.read(example_file)
    expect(result).to_not include("/app")
    expect(result).to include("/opt/my-app")
  end
end