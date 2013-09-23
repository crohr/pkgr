# This is an example software definition for a Ruby project.
#
# Lots of software definitions for popular open source software
# already exist in `opscode-omnibus`:
#
#  https://github.com/opscode/omnibus-software/tree/master/config/software
#
name "pkgr"
version "0.3.4"

dependency "ruby"
dependency "rubygems"

build do
  gem "install pkgr -n #{install_dir}/bin --no-rdoc --no-ri -v #{version}"
end
