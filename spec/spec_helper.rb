require 'rspec'

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require 'pkgr'

def fixture(name)
  File.expand_path("../fixtures/#{name}", __FILE__)
end
