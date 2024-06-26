# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'pkgr/version'

Gem::Specification.new do |s|
  s.name                      = "pkgr"
  s.version                   = Pkgr::VERSION
  s.platform                  = Gem::Platform::RUBY
  s.required_ruby_version     = '>= 1.9.3'
  s.required_rubygems_version = ">= 1.3"
  s.authors                   = ["Cyril Rohr"]
  s.email                     = ["cyril.rohr@gmail.com"]
  s.executables               = ["pkgr"]
  s.homepage                  = "http://github.com/crohr/pkgr"
  s.summary                   = "Package any Ruby, NodeJS or Go app as a deb or rpm package"
  s.description               = "Simplify the deployment of your applications by automatically packaging your application and its dependencies on multiple platforms."

  s.license = 'MIT'

  s.add_dependency('rake', '~> 12.2.1') # rake 12.3 requires ruby 2.x
  s.add_dependency('thor', '~> 1')
  s.add_dependency('fpm', '~> 1.1')
  s.add_dependency('facter', '~> 4')
  s.add_dependency('mixlib-log', '~> 1.6')
  s.add_dependency('mixlib-shellout', '~> 1.4')
  # 5+ requires ruby 2.6+
  s.add_dependency('public_suffix', '~> 4')
  # Fer el/8, old Ubuntus, SLES, etc.
  # The last version of dotenv (>= 0) to support your Ruby & RubyGems was 2.8.1. Try installing it with `gem install dotenv -v 2.8.1` and then running the current command again
  # dotenv requires Ruby version >= 3.0. The current ruby version is 2.7.7.221.
  s.add_dependency('dotenv', '~> 2.8')

  s.add_development_dependency('rspec', '~> 3')

  s.files = Dir.glob("{lib,data}/**/*") + %w(LICENSE README.md)

  s.rdoc_options = ["--charset=UTF-8"]
  s.extra_rdoc_files = [
    "LICENSE",
    "README.md"
  ]

  s.require_path = 'lib'
end
