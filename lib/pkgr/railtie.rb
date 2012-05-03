module Pkgr
  class Railtie < Rails::Railtie
    rake_tasks do
      load File.expand_path("../pkgr.rake", __FILE__)
    end
  end
end
