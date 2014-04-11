require File.dirname(__FILE__) + '/../../spec_helper'
require 'fileutils'

describe Pkgr::Buildpack do
  it "initializes with a url" do
    buildpack = Pkgr::Buildpack.new("http://some/url")
    buildpack.url.should == "http://some/url"
  end


  describe ".buildpacks_cache_dir" do
    after do
      Pkgr::Buildpack.buildpacks_cache_dir = nil
    end

    it "should have a default buildpacks cache directory" do
      expect(Pkgr::Buildpack.buildpacks_cache_dir).to eq(File.expand_path("~/.pkgr/buildpacks"))
      expect(File.directory?(Pkgr::Buildpack.buildpacks_cache_dir)).to be_true
    end

    it "should overwrite the default buildpacks cache directory" do
      dir = Dir.mktmpdir
      Pkgr::Buildpack.buildpacks_cache_dir = dir
      expect(Pkgr::Buildpack.buildpacks_cache_dir).to eq(dir)
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