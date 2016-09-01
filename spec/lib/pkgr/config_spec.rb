require File.dirname(__FILE__) + '/../../spec_helper'

describe Pkgr::Config do
  let(:options) do
    {
      :version => "0.0.1",
      :name => "my-app",
      :iteration => "1234",
      :env => ["RACK_ENV=staging", "CURL_TIMEOUT=250"]
    }
  end

  let(:config) { Pkgr::Config.new(options) }

  it "is valid" do
    expect(config).to be_valid
  end

  it "is no valid if no name given" do
    config.name = ""
    expect(config).to_not be_valid
    expect(config.errors).to include("name can't be blank")
  end

  it "is not valid if invalid version number" do
    config.version = "abcd"
    expect(config).to_not be_valid
    expect(config.errors).to include("version must start with a digit")
  end

  it "exports to cli arguments" do
    config.homepage = "http://somewhere"
    config.description = "some description"
    expect(config.to_args).to include("--description \"some description\"")
    expect(config.to_args).to include("--version \"0.0.1\"")
    expect(config.to_args).to include("--name \"my-app\"")
    expect(config.to_args).to include("--user \"my-app\"")
    expect(config.to_args).to include("--group \"my-app\"")
    expect(config.to_args).to include("--architecture \"x86_64\"")
    expect(config.to_args).to include("--homepage \"http://somewhere\"")
    expect(config.to_args).to include("--env \"RACK_ENV=staging\" \"CURL_TIMEOUT=250\"")
  end

  it "can read from a config file" do
    config = Pkgr::Config.load_file(fixture("pkgr.yml"), "debian-6")
    expect(config.name).to eq("some-awesome-app")
    expect(config.description).to eq("An awesome description here!")
    expect(config.user).to eq("git")
    expect(config.group).to eq("git")
    expect(config.homepage).to eq("http://example.org")
    expect(config.dependencies).to eq(["mysql-server", "git-core"])
    expect(config.build_dependencies).to eq(["libmagickcore-dev", "libmagickwand-dev"])
  end

  it "correctly recognizes yaml references" do
    config1 = Pkgr::Config.load_file(fixture("pkgr.yml"), "debian-6")
    config2 = Pkgr::Config.load_file(fixture("pkgr.yml"), "ubuntu-10.04")
    expect(config1.dependencies).to eq(config2.dependencies)
  end

  Pkgr::Config::DISTRO_COMPATIBILITY_MAPPING.each do  |from, to|
    it "is backwards compatible with #{from} denomination" do
      yml = {}
      yml["targets"] = {
        from => {"dependencies" => ["1", "2", "3"]}
      }
      file = Tempfile.new("config")
      file.write YAML.dump(yml)
      file.close

      config = Pkgr::Config.load_file(file.path, to)
      expect(config.dependencies).to eq(["1", "2", "3"])
    end
  end

  it "can merge two config objects together" do
    config.dependencies = ["dep1", "dep2"]
    config2 = Pkgr::Config.load_file(fixture("pkgr.yml"), "debian-6")
    new_config = config.merge(config2)

    expect(new_config.name).to eq("some-awesome-app")
    expect(new_config.home).to eq("/opt/some-awesome-app")
    expect(new_config.version).to eq("0.0.1")
    expect(new_config.user).to eq("git")
    expect(new_config.dependencies).to eq(["dep1", "dep2", "mysql-server", "git-core"])
    expect(new_config.build_dependencies).to eq(["libmagickcore-dev", "libmagickwand-dev"])
  end

  it "does not fail if a distribution is set to true" do
    Pkgr::Config.load_file(fixture("pkgr.yml"), "centos-6")
  end

  it "does not fail if a distribution is set to false" do
    Pkgr::Config.load_file(fixture("pkgr.yml"), "fedora-20")
  end

  describe "#after_hook" do
    it "returns the content of the after_precompile option if any" do
      config.after_precompile = "path/to/hook"
      expect(config.after_hook).to eq("path/to/hook")
    end

    it "creates a tmpfile with the content of the after configuration option (if any)" do
      config.after = ["do_something", "do_something_else"]
      hook = config.after_hook
      expect(hook).to_not be_empty
      expect(File.read(hook)).to eq("do_something\ndo_something_else\n")
    end
  end

  describe "#before_hook" do
    it "returns the content of the before_precompile option if any" do
      config.before_precompile = "path/to/hook"
      expect(config.before_hook).to eq("path/to/hook")
    end

    it "creates a tmpfile with the content of the before configuration option (if any)" do
      config.before = ["do_something", "do_something_else"]
      hook = config.before_hook
      expect(hook).to_not be_empty
      expect(File.read(hook)).to eq("do_something\ndo_something_else\n")
    end
  end

  describe "#crons" do
    it "has none by default" do
      expect(config.crons.length).to eq(0)
    end

    it "correctly exports the crons if any" do
      config = Pkgr::Config.new(crons: ["path/to/cron1", "path/to/cron2"])
      expect(config.crons).to eq(["path/to/cron1", "path/to/cron2"])
    end
  end

  describe "#skip_default_dependencies?" do
    context "default configuration" do
      it "returns false" do
        expect(config.skip_default_dependencies?).to eq(false)
      end

      context "when default_dependencies is set to false in .pkgr.yml" do
        let(:options) { super().merge(default_dependencies: false) }

        it "returns true" do
          expect(config.skip_default_dependencies?).to eq(true)
        end
      end

      context "when default_dependencies is set to an array in .pkgr.yml" do
        let(:options) { super().merge(default_dependencies: ['foo']) }

        it "returns false" do
          expect(config.skip_default_dependencies?).to eq(false)
        end
      end
    end

    context "when --disable-default-dependencies is passed" do
      let(:options) { super().merge(disable_default_dependencies: true) }

      it "returns true" do
        expect(config.skip_default_dependencies?).to eq(true)
      end

      context "when default_dependencies is set to an array in .pkgr.yml" do
        let(:options) { super().merge(default_dependencies: ['foo']) }

        it "returns true" do
          expect(config.skip_default_dependencies?).to eq(true)
        end
      end
    end

    context "when --no-disable-default-dependencies is passed" do
      let(:options) { super().merge(disable_default_dependencies: false) }

      it "returns false" do
        expect(config.skip_default_dependencies?).to eq(false)
      end

      context "when default_dependencies is set to false in .pkgr.yml" do
        let(:options) { super().merge(default_dependencies: false) }

        it "returns false" do
          expect(config.skip_default_dependencies?).to eq(false)
        end
      end
    end
  end

  describe '#cli?' do
    context "default configuration" do
      it "returns false" do
        expect(config.cli?).to eq(true)
      end
    end

    context 'when the --disable-cli flag is not passed' do
      context "when cli is set to false in .pkgr.yml" do
        let(:options) { super().merge(cli: false) }

        it "returns false" do
          expect(config.cli?).to eq(false)
        end
      end
    end

    context 'when the --disable-cli flag is passed' do
      let(:options) { super().merge(disable_cli: true) }

      it "returns false" do
        expect(config.cli?).to eq(false)
      end
    end

    context 'when the --no-disable-cli flag is passed' do
      let(:options) { super().merge(disable_cli: false) }

      it "returns true" do
        expect(config.cli?).to eq(true)
      end

      context "when cli is set to false in .pkgr.yml" do
        let(:options) { super().merge(cli: false) }

        it "returns true" do
          expect(config.cli?).to eq(true)
        end
      end
    end
  end
end
