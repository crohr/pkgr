#!/bin/bash

set -e

PATH="/usr/local/bin:$PATH"
RUBY_VERSION="2.1.3"

apt-get -qq -y update

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

install_ruby() {
  curl -sSL -G buildcurl.com -d recipe=ruby -d target=ubuntu:16.04 -d version=$RUBY_VERSION -d prefix=/usr/local -o - | tar xzf - -C /usr/local
}

[ -f /usr/local/bin/ruby ] || install_ruby
bundle -v || ( gem install bundler --no-ri --no-rdoc )
# default to /vagrant when logging in
( grep -q "cd /vagrant" /home/ubuntu/.bash_profile ) || ( echo "cd /vagrant" >> /home/ubuntu/.bash_profile )

echo "127.0.0.1 ubuntu-xenial" >> /etc/hosts
