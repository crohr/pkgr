require File.dirname(__FILE__) + '/../../../spec_helper'

describe Pkgr::Templates::FileTemplate do
  before do
    @tmpfile = Tempfile.new("target")
  end

  after do
    @tmpfile.unlink
  end

  let(:template) { Pkgr::Templates::FileTemplate.new(@tmpfile.path, File.new(fixture("default.erb"))) }
  let(:config) { Pkgr::Config.new(:home => "/opt/my-app", :name => "my-app") }

  it "writes the expected result to the target file" do
    template.install(config.sesame)
    @tmpfile.rewind
    expect(@tmpfile.read).to include(%{HOME="/opt/my-app"})
  end

end