# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'pkgr/version'

Gem::Specification.new do |s|
  s.name                      = "pkgr"
  s.version                   = Pkgr::VERSION
  s.platform                  = Gem::Platform::RUBY
  s.required_ruby_version     = '>= 1.8.7'
  s.required_rubygems_version = ">= 1.3"
  s.authors                   = ["Cyril Rohr"]
  s.email                     = ["cyril.rohr@gmail.com"]
  s.executables               = ["pkgr"]
  s.homepage                  = "http://github.com/crohr/pkgr"
  s.summary                   = "Package any app as a debian package"
  s.description               = "Embeds your app dependencies (e.g. a specific ruby version and you gems in the case of Rails apps) into a debian package, for easy installation. Provides init scripts and more."

  s.license = 'MIT'

  s.add_dependency('rake')
  s.add_dependency('thor')
  s.add_dependency('fpm')
  s.add_dependency('facter')
  s.add_dependency('mixlib-log')
  s.add_dependency('mixlib-shellout')
  s.add_development_dependency('rspec', '~> 2')

  s.files = Dir.glob("{lib}/**/*") + %w(LICENSE README.md)

  s.rdoc_options = ["--charset=UTF-8"]
  s.extra_rdoc_files = [
    "LICENSE",
    "README.md"
  ]

  s.require_path = 'lib'
end
