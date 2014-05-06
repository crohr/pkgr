## 1.3.1 - 20140506

* Add buildpacks for Ubuntu 14.04.
* Add support for pre/post install files.

## 1.3.0 - 20140502

* CLI: Support for Ubuntu Trusty 14.04
* Put the CLI in /usr/bin.
* Properly set HOME environment variable to /home/:user
* Add more relaxed timeouts on ruby buildpacks.
* Add PROCESS_MANAGER env variable if custom runner is forced.
* Fix issues with .pkgr.yml custom runner not being picked up
* Allow to force a custom runner (upstart, sysvinit).
* Handles termination of processes that fork upon starting.
* Fix sysvinit script.
* Fix permissions on /etc/appname.
* Fix dependencies installation.
* Make user:group the owner of /etc/appname/*
* Add tests for CLI
* CentOS experimental support
* Added --after-precompile and --license options.
* Move slow test to integration.
* Outputs buildpack cloning step.

## 1.2.0 - 20140409

* Add --buildpack-list option, with support for environment variables to be given to a buildpack.
* Reduce list of builtin buildpacks to Ruby and NodeJS.
* Remove upstart dependency.
* Add sysvinit support for debian distros.
* Fix PORT_NUM substitution.
* Allow to set a maintainer for the package.
* Rescue more errors, for better display.
* Add debug output when launching buildpack compile command.

## 1.1.8 - 20140326

* Fix master init script.
* Allow after hooks.

## 1.1.7 - 20140325

* Expand given path when packaging.

## 1.1.6 - 20140320

* Correctly export environment variables in /etc/default/your-app.
