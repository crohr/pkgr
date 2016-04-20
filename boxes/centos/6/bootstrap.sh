#!/bin/bash

set -e

PATH="/usr/local/bin:$PATH"
RUBY_VERSION="1.9.3-p545"
RUBYGEMS_VERSION="2.2.1"
BUNDLER_VERSION="1.6.1"

# yum check-update

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
