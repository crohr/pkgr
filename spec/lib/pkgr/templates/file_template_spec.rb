require File.dirname(__FILE__) + '/../../../spec_helper'

describe Pkgr::Templates::FileTemplate do
  before do
    @tmpfile = Tempfile.new("target")
  end

  after do
    @tmpfile.unlink
  end

  let(:template) { Pkgr::Templates::FileTemplate.new(@tmpfile.path, File.new(fixture("default.erb"))) }
  let(:options) { {name: "my-app"} }
  let(:config) { Pkgr::Config.new(options) }

  it "writes the expected result to the target file" do
    template.install(config.sesame)
    @tmpfile.rewind
    expect(@tmpfile.read).to include(%{HOME="/opt/my-app"})
  end

  context "tmpfile configuration" do
    context "with custom tmpdir" do
      let(:custom_tmpdir) { 'custom_tmpdir' }
      let(:options) { super().merge(tmpdir: custom_tmpdir) }

      it "sets TMPDIR to the custom tmpdirs value" do
        template.install(config.sesame)
        @tmpfile.rewind
        expect(@tmpfile.read).to include(%{tmpfile=$(TMPDIR="#{custom_tmpdir}" mktemp)})
      end
    end

    context "without custom tmpfile" do
      it "does not set TMPDIR" do
        template.install(config.sesame)
        @tmpfile.rewind
        tmpfile_content = @tmpfile.read
        expect(tmpfile_content).to_not include("TMPDIR")
        expect(tmpfile_content).to include("tmpfile=$(mktemp)")
      end
    end
  end
end