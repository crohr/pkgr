require File.dirname(__FILE__) + '/../../spec_helper'

describe Pkgr::Addon do
  let(:shell) { double 'Shell' }

  def expect_download(url, target)
    expect(shell).to receive(:run!).once.with(
      "curl -L --max-redirs 3 --retry 5 -s '#{url}' | tar xzf - --strip-components=1 -C '#{target}'"
    )
  end

  describe "name and url" do
    it "does not change the name if repo user set" do
      addon = Pkgr::Addon.new("crohr/addon-mysql")
      expect(addon.name).to eq("mysql")

      expect_download 'https://github.com/crohr/addon-mysql/archive/master.tar.gz', 'somedir/mysql'
      addon.install! 'somedir', shell
    end

    it "defaults to pkgr/name if no repo user set" do
      addon = Pkgr::Addon.new("addon-mysql")
      expect(addon.name).to eq("mysql")

      expect_download 'https://github.com/pkgr/addon-mysql/archive/master.tar.gz', 'somedir/mysql'
      addon.install! 'somedir', shell
    end

    it "defaults to pkgr/name if no repo user set" do
      addon = Pkgr::Addon.new("mysql")
      expect(addon.name).to eq("mysql")

      expect_download 'https://github.com/pkgr/addon-mysql/archive/master.tar.gz', 'somedir/mysql'
      addon.install! 'somedir', shell
    end

    it "accepts HTTP URIs" do
      addon = Pkgr::Addon.new("https://github.com/crohr/addon-mysql")
      expect(addon.name).to eq("mysql")

      expect_download 'https://github.com/crohr/addon-mysql/archive/master.tar.gz', 'somedir/mysql'
      addon.install! 'somedir', shell
    end

    it "accepts full URLs for git repositories" do
      addon = Pkgr::Addon.new("https://github.com/crohr/addon-mysql.git")
      expect(addon.name).to eq("mysql")

      expect_download 'https://github.com/crohr/addon-mysql/archive/master.tar.gz', 'somedir/mysql'
      addon.install! 'somedir', shell
    end

    it "accepts full URLs for git repositories including a branch" do
      addon = Pkgr::Addon.new("https://github.com/crohr/addon-mysql.git#foo-branch")
      expect(addon.name).to eq("mysql")

      expect_download 'https://github.com/crohr/addon-mysql/archive/foo-branch.tar.gz', 'somedir/mysql'
      addon.install! 'somedir', shell
    end

    it "accepts a relative file path" do
      addon = Pkgr::Addon.new(Pathname("./spec/fixtures/addon-mysql").realpath)
      expect(addon.name).to eq("mysql")

      addon.install! 'spec/tmp/somedir'

      expect(File.exists?('spec/tmp/somedir/mysql/bin/compile')).to be true
    end
  end
end
