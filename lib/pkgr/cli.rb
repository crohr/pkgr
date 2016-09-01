require "thor"
require 'pkgr'
require 'pkgr/buildpack'
require 'pkgr/env'

module Pkgr
  class CLI < Thor
    no_tasks do
      def self.default_data_dir
        File.expand_path("../../../data", __FILE__)
      end
    end

    class_option :verbose,
      :type => :boolean,
      :default => false,
      :desc => "Run verbosely"
    class_option :debug,
      :type => :boolean,
      :default => false,
      :desc => "Run very verbosely"
    class_option :name,
      :type => :string,
      :desc => "Application name (if directory given, it will default to the directory name)"
    class_option :buildpacks_cache_dir,
      :type => :string,
      :desc => "Directory where to store the buildpacks",
      :default => Pkgr::Buildpack.buildpacks_cache_dir

    desc "package TARBALL|DIRECTORY", "Package the given tarball or directory, as a deb or rpm depending on the build machine"

    method_option :buildpack,
      :type => :string,
      :desc => "Custom buildpack to use"
    method_option :buildpack_list,
      :type => :string,
      :desc => "Specify a file containing a list of buildpacks to use (--buildpack takes precedence if given)"
    method_option :changelog,
      :type => :string,
      :desc => "Changelog"
    method_option :maintainer,
      :type => :string,
      :desc => "Maintainer"
    method_option :vendor,
      :type => :string,
      :desc => "Package vendor"
    method_option :architecture,
      :type => :string,
      :default => "x86_64",
      :desc => "Target architecture for the package"
    method_option :runner,
      :type => :string,
      :desc => "Force a specific runner (e.g. upstart-1.5, sysv-lsb-1.3)"
    method_option :homepage,
      :type => :string,
      :desc => "Project homepage"
    method_option :description,
      :type => :string,
      :desc => "Project description"
    method_option :category,
      :type => :string,
      :default => "none",
      :desc => "Category this package belongs to"
    method_option :version,
      :type => :string,
      :desc => "Package version (if git directory given, it will use the latest git tag available)"
    method_option :iteration,
      :type => :string,
      :default => Time.now.strftime("%Y%m%d%H%M%S"),
      :desc => "Package iteration (you should keep the default here)"
    method_option :license,
      :type => :string,
      :default => nil,
      :desc => "The license of your package (see <https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/#license-short-name>)"
    method_option :user,
      :type => :string,
      :desc => "User to run the app under (defaults to your app name)"
    method_option :group,
      :type => :string,
      :desc => "Group to run the app under (defaults to your app name)"
    method_option :compile_cache_dir,
      :type => :string,
      :desc => "Where to store the files cached between packaging runs. Path will be resolved from the temporary code repository folder, so use absolute paths if needed."
    method_option :before_precompile,
      :type => :string,
      :desc => "Provide a script to run just before the buildpack compilation, on the build machine. Path will be resolved from the temporary code repository folder, so use absolute paths if needed."
    method_option :after_precompile,
      :type => :string,
      :desc => "Provide a script to run just after the buildpack compilation, on the build machine. Path will be resolved from the temporary code repository folder, so use absolute paths if needed."
    method_option :before_install,
      :type => :string,
      :desc => "Provide a script to run just before a package gets installated or updated, on the target machine."
    method_option :after_install,
      :type => :string,
      :desc => "Provide a script to run just after a package gets installated or updated, on the target machine."
#Before and after Remove
    method_option :before_remove,
      :type => :string,
      :desc => "Provide a script to run just before a package gets uninstallated, on the target machine."
    method_option :after_remove,
      :type => :string,
      :desc => "Provide a script to run just after a package gets uninstallated, on the target machine."

    method_option :dependencies,
      :type => :array,
      :default => [],
      :desc => "Specific system dependencies that you want to install with the package"
    method_option :build_dependencies,
      :type => :array,
      :default => [],
      :desc => "Specific system dependencies that must be present before building"
    method_option :disable_default_dependencies,
      :type => :boolean,
      :default => false,
      :desc => "Disable default dependencies"
    method_option :host,
      :type => :string,
      :desc => "Remote host to build on (default: local machine)"
    method_option :auto,
      :type => :boolean,
      :default => false,
      :desc => "Automatically attempt to install missing dependencies"
    method_option :clean,
      :type => :boolean,
      :default => true,
      :desc => "Automatically clean up temporary dirs"
    method_option :edge,
      :type => :boolean,
      :default => true,
      :desc => "Always use the latest version of the buildpack if already installed"
    method_option :env,
      :type => :array,
      :default => [],
      :desc => 'Specify environment variables for buildpack (--env "CURL_TIMEOUT=2" "BUNDLE_WITHOUT=development test")'
    method_option :force_os,
      :type => :string,
      :desc => 'Force a specific distribution to build for (e.g. --force-os "ubuntu-12.04"). This may result in a broken package.'
    method_option :store_cache,
      :type => :boolean,
      :desc => 'Output a tarball of the cache in the current directory (name: cache.tar.gz)'
    method_option :verify,
      :type => :boolean,
      :default => true,
      :desc => "Verifies output package"
    method_option :data_dir,
      :type => :string,
      :default => default_data_dir,
      :desc => "Custom path to data directory. Can be used for overriding default templates, hooks(pre-, post- scripts), configs (buildpacks, distro dependencies), environments, etc."
    method_option :directories,
      :type => :string,
      :default => nil,
      :desc => "Recursively mark a directory as being owned by the package"
    method_option :disable_cli,
      :type => :boolean,
      :default => false,
      :desc => "Disable installing CLI"

    def package(tarball)
      Pkgr.level = Logger::INFO if options[:verbose]
      Pkgr.level = Logger::DEBUG if options[:debug]
      Pkgr.data_dir = options[:data_dir]

      Pkgr::Buildpack.buildpacks_cache_dir = options[:buildpacks_cache_dir] if options[:buildpacks_cache_dir]

      packager = Dispatcher.new(tarball, options)
      packager.call
    rescue => e
      Pkgr.debug "#{e.class.name} : #{e.message}"
      e.backtrace.each{|line| Pkgr.debug line}
      puts "     ! ERROR: #{e.message}"
      exit 1
    # Only used for logging. Re-raise immediately.
    rescue Exception => e
      Pkgr.debug "#{e.class.name} : #{e.message}"
      e.backtrace.each{|line| Pkgr.debug line}
      puts "     ! SYSTEM ERROR: #{e.class.name} : #{e.message}"
      raise e
    end
  end
end
