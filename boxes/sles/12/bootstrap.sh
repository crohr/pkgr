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

zypper install -y postgresql-server
echo "CREATE USER \"user\" SUPERUSER PASSWORD 'pass';" | su - postgres -c psql && \
	echo "CREATE DATABASE dbname;" | su - postgres -c psql && \
	echo "GRANT ALL PRIVILEGES ON DATABASE \"dbname\" TO \"user\";" | su - postgres -c psql

cat > /var/lib/pgsql/data/pg_hba.conf <<CONFIG
local   all             all                                     peer
host    all             all             127.0.0.1/32            md5
host    all             all             ::1/128                 md5
CONFIG

sed -i "s|#listen_addresses = 'localhost'|listen_addresses = 'localhost'|" /var/lib/pgsql/data/postgresql.conf

systemctl restart postgresql

cd /vagrant/pkgr
bundle
