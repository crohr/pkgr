require 'rake'
require 'erb'

module Pkgr
  class App
    include RakeFileUtils
    attr_reader :root
    attr_reader :errors
    attr_reader :config

    # +root+: the root directory of the app.
    # +config+ a Configuration object, hosting the parameters defined in `config/pkgr.yml`.
    def initialize(root, config_path)
      @root = root
      load_config(config_path)
      @errors = []
    end

    def load_config(path)
      @config = YAML::load_file(path)
      raise ArgumentError, "The given configuration file at '#{path}' is not a well-formed YAML file. Please fix it or remove it and run 'rake pkgr:setup'" unless @config.kind_of?(Hash)
      @config['_path'] = path
    end
    
    def write_config
      File.open(@config['_path'] || raise("Don't know where to save myself!"), "w+") {|f|
        YAML.dump(@config.reject{|k,v| k == '_path'}, f)
      }
    end

    # Returns true if the app is correctly configured. Else otherwise.
    def valid?
      @errors.clear
      @errors.push("is not a valid git repository") unless File.exist?(File.join(@root, ".git", "HEAD"))
      @errors.push("must have a name") unless @config.fetch('name')
      @errors.push("must have a valid name ([a-zA-Z0-9_-])") unless @config.fetch('name').scan(/[^a-z0-9\_\-]/i)
      @errors.push("must have a version") unless @config.fetch('version')
      @errors.push("must have a valid target architecture") unless @config.fetch('architecture')
      @errors.empty?
    end

    def generate_required_files
      setup_debian
      setup_binary
    end

    def git_ref
      @config.fetch('git_ref') { 'HEAD' }
    end

    def prefix
      @config.fetch('prefix') { "/opt/local" }
    end

    def author_name
      @author_name ||= `git config --get user.name`.chomp
    end

    def author_email
      @author_email ||= `git config --get user.email`.chomp
    end

    def name
      @config['name']
    end

    def description
      @config['description'] || ""
    end

    def debian_build_dependencies(installable_only = false)
      deps = @config['debian_build_dependencies'] || []
      if installable_only
        deps = deps.reject{|d| d =~ /[\$\{\}]/}.map{|d| d.split(/\s/)[0]}
      end
      deps
    end

    def debian_runtime_dependencies(installable_only = false)
      deps = @config['debian_runtime_dependencies'] || []
      if installable_only
        deps = deps.reject{|d| d =~ /[\$\{\}]/}.map{|d| d.split(/\s/)[0]}
      end
      deps
    end

    def architecture
      @config['architecture'] || "all"
    end

    def homepage
      @config['homepage'] || ""
    end

    def config_files
      @config['config_files'] || []
    end

    def version
      @config['version']
    end
    
    def user
      @config.fetch('user') { name }
    end
    
    def group
      @config.fetch('group') { name }
    end

    # prefix without the leading slash.
    def pkg_prefix
      prefix[1..-1]
    end

    def setup_debian
      target = File.join(root, Pkgr::DEBIAN_DIR)
      Pkgr.mkdir(target)

      Dir[File.expand_path("../data/debian/*", __FILE__)].each do |file|
        case File.extname(file)
        when ".erb"
          file_target = File.join(target, File.basename(file, ".erb"))
          File.open(file_target, "w+") do |f|
            f << ERB.new(File.read(file)).result(binding)
          end
        else
          file_target = File.join(target, File.basename(file))
          if File.exist?(file_target)
            puts "File #{file_target} already exists. Skipped."
          else
            FileUtils.cp(file, file_target, :verbose => true)
          end
        end
      end

      puts "Correctly set up debian files."
    end

    # Creates an executable file for easy launch of the server/console/rake tasks once it is installed.
    # E.g. /usr/bin/my-app console, /usr/bin/my-app server start -p 8080
    def setup_binary
      target = File.join(root, "bin", name)
      Pkgr.mkdir(File.dirname(target))
      FileUtils.cp(File.expand_path("../data/bin/executable", __FILE__), target, :verbose => true)
      FileUtils.chmod 0755, target, :verbose => true
      puts "Correctly set up executable file. Try running './bin/#{name} console'."
    end

    # FIXME: this is ugly
    def bump!(version_index = :patch)
      indices = [:major, :minor, :patch]
      index = indices.index(version_index) || raise(ArgumentError, "The given version index is not valid (#{version_index})")
      version = @config.fetch('version') { '0.0.0' }
      fragments = version.split(".")
      fragments[index] = fragments[index].to_i+1
      ((index+1)..2).each{|i|
        fragments[i] = 0
      }
      new_version = fragments.join(".")

      changelog = File.read(debian_file("changelog"))

      last_commit = changelog.scan(/\s+\* ([a-z0-9]{7}) /).flatten[0]

      cmd = "git log --oneline"
      cmd << " #{last_commit}..#{git_ref}" unless last_commit.nil?
      result = %x{#{cmd}}
      ok = $?.exitstatus == 0
      if !ok
        raise "Command failed. Aborting."
      else
        content_changelog = [
          "#{name} (#{new_version}-1) unstable; urgency=low",
          "",
          result.split("\n").reject{|l| l =~ / v#{version}/}.map{|l| "  * #{l}"}.join("\n"),
          "",
          " -- #{author_name} <#{author_email}>  #{Time.now.strftime("%a, %d %b %Y %H:%M:%S %z")}",
          "",
          changelog
        ].join("\n")

        File.open(debian_file("changelog"), "w+") do |f|
          f << content_changelog
        end

        @config['version'] = new_version
        write_config

        puts "Committing changelog and version file..."
        files_to_commit = [debian_file('changelog'), @config['_path']]
        sh "git add #{files_to_commit.join(" ")} && git commit -m 'v#{new_version}' #{files_to_commit.join(" ")}"
      end
    end

    def build_debian_package(host)
      puts "Building debian package on '#{host}'..."
      Dir.chdir(root) do
        Pkgr.mkdir("pkg")
        case host
        when 'localhost'
          debian_steps.each do |step|
            sh step
          end
        else
          archive = "#{name}-#{version}"
          sh "scp #{File.expand_path("../data/config/pre_boot.rb", __FILE__)} #{host}:/tmp/"
          cmd = %Q{
            git archive #{git_ref} --prefix=#{archive}/ | ssh #{host} 'cat - > /tmp/#{archive}.tar &&
              set -x && rm -rf /tmp/#{archive} &&
              cd /tmp && tar xf #{archive}.tar && cd #{archive} &&
              cat config/boot.rb >> /tmp/pre_boot.rb && cp -f /tmp/pre_boot.rb config/boot.rb &&
              #{debian_steps.join(" &&\n")}'
          }
          sh cmd
          # Fetch the .deb, and put it in the `pkg` directory
          sh "scp #{host}:/tmp/#{name}_#{version}*.deb pkg/"
        end
      end
    end

    def debian_steps
      target_vendor = "vendor/bundle/ruby/1.9.1"
      [
        "sudo apt-get install #{debian_runtime_dependencies(true).join(" ")} -y",
        "sudo apt-get install #{debian_build_dependencies(true).join(" ")} -y",
        # Vendor bundler
        "gem1.9.1 install bundler --no-ri --no-rdoc --version #{bundler_version} -i #{target_vendor}",
        "GEM_HOME='#{target_vendor}' #{target_vendor}/bin/bundle install --deployment --without test development",
        "rm -rf #{target_vendor}/{cache,doc}",
        "dpkg-buildpackage -us -uc -d"
      ]
    end

    private
    def bundler_version
      @config.fetch('bundler_version') { '1.1.3' }
    end

    def debian_file(filename)
      file = File.join(Pkgr::DEBIAN_DIR, filename)
      return nil unless File.exist?(file)
      file
    end
  end
end