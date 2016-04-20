#!/bin/bash

set -e

BUNDLER_VERSION="1.7.12"

apt-get -y update

apt-get -y install \
  wget \
  git \
  sudo \
  lsb-release \
  curl \
  libssl1.0.0 \
  libmysqlclient-dev \
  libpq-dev \
  libsqlite3-0 \
  libevent-dev \
  libssl-dev \
  libxml2-dev \
  libxslt1-dev \
  libreadline-dev \
  build-essential

ruby -v || curl https://s3.amazonaws.com/pkgr-buildpack-ruby/current/debian-8/ruby-2.2.2.tgz -o - | tar xzf - -C /usr/local

( bundle -v | grep "${BUNDLER_VERSION}" ) || ( gem install bundler --no-ri --no-rdoc --version "${BUNDLER_VERSION}" )
# default to /vagrant when logging in
( grep "cd /vagrant" /home/vagrant/.bash_profile ) || ( echo "cd /vagrant" >> /home/vagrant/.bash_profile )

echo "nameserver 8.8.8.8
nameserver 4.4.4.4" > /etc/resolv.conf

echo "DONE"
