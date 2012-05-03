# This part of code is added by Pkgr, before the original content of the
# `config/boot.rb` file.
require 'rubygems'

# Attempts to use a vendored Bundler, if any
vendored_gems = File.expand_path(
  '../../vendor/bundle/ruby/1.9.1/gems', __FILE__
)

vendored_bundler = Dir["#{vendored_gems}/bundler-*/lib"].sort.last

if !vendored_bundler.nil? && !$LOAD_PATH.include?(vendored_bundler)
  $LOAD_PATH.unshift(vendored_bundler)
end

