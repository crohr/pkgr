# ROOT=. rake -I lib -f lib/pkgr/pkgr.rake pkgr:setup

require 'pkgr'
require 'fileutils'

ROOT = ENV.fetch('ROOT') { Rails.root }
CONFIG = ENV.fetch('CONFIG') { File.join(ROOT, "config/pkgr.yml") }
if File.exist?(CONFIG)
  APP = Pkgr::App.new ROOT, CONFIG
  APP.valid? || fail("There is an issue with the app you're trying to package: #{APP.errors.join(", ")}")
end

namespace :pkgr do

  desc "Setup the required files for pkgr"
  task :setup do
    Pkgr.setup(ROOT)
  end

  if defined?(APP)
    task :generate do
      APP.generate_required_files
    end

    namespace :bump do
      %w{patch minor major}.each do |version|
        desc "Increments the #{version} version by one"
        task version.to_sym do
          APP.bump!(version.to_sym)
        end
      end
    end

    namespace :build do
      desc "Builds the debian package"
      task :deb do
        build_host = ENV.fetch('HOST') { 'localhost' }
        APP.build_debian_package(build_host)
      end
    end
  end
end