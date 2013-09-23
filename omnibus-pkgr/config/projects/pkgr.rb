
name "pkgr"
maintainer "Cyril Rohr"
homepage "http://crohr.me/pkgr"

replaces        "pkgr"
install_path    "/opt/pkgr"
build_version   Omnibus::BuildVersion.new.semver
build_iteration 1

# creates required build directories
dependency "preparation"
dependency "pkgr"

# pkgr dependencies/components
# dependency "somedep"

# version manifest file
dependency "version-manifest"

exclude "\.git*"
exclude "bundler\/git"
