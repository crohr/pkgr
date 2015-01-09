#!/bin/bash

set -e

PATH="/usr/local/bin:$PATH"
RUBY_VERSION="1.9.3-p545"
RUBYGEMS_VERSION="2.2.1"
BUNDLER_VERSION="1.6.1"

echo "nameserver 8.8.8.8
nameserver 4.4.4.4" > /etc/resolv.conf

zypper ar --no-gpgcheck "http://cache.packager.io/SLE-12-SDK-DVD-x86_64-GM-DVD1" "SLES12 SDK DVD1" || true

zypper install -y ruby2.1 ruby2.1-devel git-core
gem install bundler --no-ri --no-rdoc
ln -fs /usr/bin/bundle.ruby2.1 /usr/bin/bundle

cd /vagrant
test -d "pkgr" || git clone https://github.com/crohr/pkgr.git
cd pkgr
bundle
