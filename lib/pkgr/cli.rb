require "thor"

module Pkgr
  class CLI < Thor
    class_option :verbose,    :type => :boolean, :default => false, :desc => "Run verbosely"
    class_option :name,       :type => :string, :desc => "Application name"
  end
end