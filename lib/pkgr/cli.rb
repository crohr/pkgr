require "thor"

module Pkgr
  class CLI < Thor
    class_option :verbose,    :type => :boolean, :default => false, :desc => "Run verbosely"
    class_option :name,       :type => :string, :default => File.basename(Dir.pwd), :desc => "Application name"


    desc "package TARBALL", "Package the given tar file"

    method_option :target,            :type => :string, :default => "deb", :desc => "Target package to build (only 'deb' supported for now)"
    method_option :changelog,         :type => :string, :desc => "Changelog"
    method_option :architecture,      :type => :string, :default => "x86_64", :desc => "Target architecture for the package"
    method_option :codename,          :type => :string, :default => "lucid", :desc => "Target distribution"
    # method_option :sign_key,      :type => :string, :desc => "Key to be used to sign the generated package [default=#{DEFAULT_SIGN_KEY}]"
    method_option :homepage,          :type => :string, :desc => "Project homepage"
    method_option :version,           :type => :string, :desc => "Package version (will be guessed from your git repository -- using tags -- if available)"
    method_option :iteration,         :type => :string, :default => Time.now.strftime("%Y%m%d%H%M%S"), :desc => "Package iteration (you should keep the default here)"
    method_option :user,              :type => :string, :desc => "User to run the app under (defaults to your app name)"
    method_option :group,             :type => :string, :desc => "Group to run the app under (defaults to your app name)"
    method_option :compile_cache_dir, :type => :string, :desc => "Where to store the files cached between packaging runs"

    def package(tarball)
      packager = Dispatcher.new(tarball, options)
      packager.call
    rescue Pkgr::Errors::Base => e
      Pkgr.error "#{e.class.name} : #{e.message}"
      puts "* ERROR: #{e.message}"
      exit 1
    end
  end
end