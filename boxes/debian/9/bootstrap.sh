#!/bin/bash

set -e

BUNDLER_VERSION="1.15.3"

apt-get -y update

apt-get -y install \
  wget \
  git \
  sudo \
  lsb-release \
  curl \
  libssl1.0.2 \
  default-libmysqlclient-dev \
  libpq-dev \
  libsqlite3-0 \
  libevent-dev \
  libssl-dev \
  libxml2-dev \
  libxslt1-dev \
  libreadline-dev \
  build-essential

ruby -v || curl -sGL buildcurl.com -d recipe=ruby -d version=2.4.0 -d target=debian:9 -o - | tar xzf - -C /usr/local

( bundle -v | grep "${BUNDLER_VERSION}" ) || ( gem install bundler --no-ri --no-rdoc --version "${BUNDLER_VERSION}" )

# default to /vagrant when logging in
cat > /home/vagrant.bash_profile <<CONF
export HOME=/home/vagrant
cd /vagrant
CONF

echo "nameserver 8.8.8.8
nameserver 4.4.4.4" > /etc/resolv.conf

# required for libffi to install properly it seems
ln -s /usr/bin/install /bin/install

echo "DONE"
