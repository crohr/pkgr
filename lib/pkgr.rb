require 'pkgr/app'
require 'pkgr/railtie' if defined?(Rails)

module Pkgr
  DEBIAN_DIR = "debian"

  def self.setup(root)
    setup_config(root)
  end

  protected

  def self.setup_config(root)
    puts "Setting up configuration file..."
    target = File.join(root, "config", "pkgr.yml")
    FileUtils.mkdir_p(File.dirname(target))
    if File.exist?(target)
      puts "'#{target}' already exists. Skipped."
    else
      FileUtils.cp(File.expand_path("../pkgr/data/pkgr.yml", __FILE__), target, :verbose => true)
      puts "Edit '#{target}' and fill in the required information, then enter 'rake pkgr:generate' to generate the debian files."
    end
  end

  
  def self.mkdir(target)
    if File.directory?(target)
      puts "#{target} directory already exists. Skipped."
    elsif File.file?(target)
      raise "#{target} already exists and is a file. Aborting."
    else
      FileUtils.mkdir_p target, :verbose => true
    end
  end
end