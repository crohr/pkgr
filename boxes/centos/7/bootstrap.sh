#!/bin/bash

set -e

PATH="/usr/local/bin:$PATH"
BUNDLER_VERSION="1.7.12"

yum -y install \
  git \
  vim \
  sudo \
  wget \
  curl \
  openssl-devel \
  readline-devel \
  libxml2-devel \
  libxslt-devel \
  libevent-devel \
  postgresql-devel \
  mysql-devel \
  sqlite-devel \
  gcc gcc-c++ kernel-devel

yum install -y rpm-build

ruby -v || curl https://s3.amazonaws.com/pkgr-buildpack-ruby/current/centos-7/ruby-2.2.2.tgz -o - | tar xzf - -C /usr/local

( bundle -v | grep "${BUNDLER_VERSION}" ) || ( gem install bundler --no-ri --no-rdoc --version "${BUNDLER_VERSION}" )

# default to /vagrant when logging in
( grep "cd /vagrant" /home/vagrant/.bash_profile ) || ( echo "cd /vagrant" >> /home/vagrant/.bash_profile )

echo "nameserver 8.8.8.8
nameserver 4.4.4.4" > /etc/resolv.conf
