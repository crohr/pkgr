#!/bin/bash

set -e

PATH="/usr/local/bin:$PATH"
RUBY_VERSION="1.9.3-p545"
RUBYGEMS_VERSION="2.2.1"
BUNDLER_VERSION="1.6.1"

apt-get -y update

apt-get -y install \
  wget \
  git \
  sudo \
  lsb-release \
  curl \
  libssl0.9.8 \
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
  cd /usr/local/src/ && wget --quiet http://pyyaml.org/download/libyaml/yaml-0.1.6.tar.gz && tar xzf yaml-0.1.6.tar.gz
  cd /usr/local/src/yaml-0.1.6/ && ./configure --prefix=/usr/local && make && make install

  cd /usr/local/src/ && wget --quiet ftp://ftp.ruby-lang.org/pub/ruby/1.9/ruby-${RUBY_VERSION}.tar.gz && tar xzf ruby-${RUBY_VERSION}.tar.gz
  cd /usr/local/src/ruby-${RUBY_VERSION}/ && ./configure --prefix=/usr/local --enable-shared --disable-install-doc --with-opt-dir=/usr/local/lib --with-openssl-dir=/usr/local && make && make install
}

install_rubygems() {
  cd /usr/local/src/ && wget --quiet http://production.cf.rubygems.org/rubygems/rubygems-${RUBYGEMS_VERSION}.tgz && tar xzf rubygems-${RUBYGEMS_VERSION}.tgz
  cd /usr/local/src/rubygems-${RUBYGEMS_VERSION}/ && ruby setup.rb --prefix=/usr/local
}

[ -f /usr/local/bin/ruby ] || install_ruby
( gem -v | grep "${RUBYGEMS_VERSION}" ) || install_rubygems
( bundle -v | grep "${BUNDLER_VERSION}" ) || ( gem install bundler --no-ri --no-rdoc --version "${BUNDLER_VERSION}" )
# default to /vagrant when logging in
( grep "cd /vagrant" /home/vagrant/.bash_profile ) || ( echo "cd /vagrant" >> /home/vagrant/.bash_profile )

echo "nameserver 8.8.8.8
nameserver 4.4.4.4" > /etc/resolv.conf
