## 1.5.0 - 20160908

* Fix upstart job for CentOS
* Reinstall master and process master init scripts whenever scale is called
* Run chroot with the user's configured groups
* Add SLES11 support
* Fix postinstall shebang
* Can now disable default dependencies with `default_dependencies: false`
* Allow to override `data_dir` folder
* Generate init files with correct PORT
* Allow hard-coded defaults to be overridden by pkgr.yml
* Pass ENV_DIR to compile script
* Replace only instances of `/app/` and not `/app` in buildpacks
* Create /app dir, which is required by some buildpacks to compile (e.g. GO)
* Pass TARGET as an env variable when compiling, so that it can be used to fetch binaries from buildcurl.com
* Add possibility to set category and directories fpm option
* Support for Ubuntu 16.04
* Add command-line flags for disabling default dependencies and CLI

## 1.4.4 - 20150512

* Add CentOS / RHEL 7 support with systemd
* Add Debian 8 "jessie" support with systemd
* Upstart: make sure to start once filesystem is up
* Add Amazon Linux 2015 support
* Allow addons to be installed from a local relative path
* Add SLES12 support
* Extract SVN version number, if available
* Changed interpreter in maintainer scripts to /bin/bash in order to avoid forbidden-postrm-interpreter errors on Debian 7

## 1.4.3 - 20150304

* Allow to run some commands as the APP_USER instead of root
* Some profile.d scripts output stuff (e.g. newest nodejs buildpack), so redirect to /dev/null

## 1.4.2 - 20150227

* Use Shellwords to escape command line args
* Allow scaledowns to finish even if stopping the service does not work
* Retry the packaging command at most 3 times if the package verification failed
* Add CLI options for `--before-remove` and `--after-remove` scripts
* Make sure `.git` directories are not included in the resulting package

## 1.4.1 - 20150217

* Allow to set config variables with equal signs in their values
* Add --vendor option
* Add net-tools to dependencies when using installer
* Add which to dependencies when using installer
* Add support for SLES12 (rpm)
* Get remote compiling working
* All processes from Procfile are now exported as potential services
* Add option to verify the generated packages
* CLI support: allow to overwrite default CLI to point to custom executable

## 1.4.0 - 20141015

* Add support for Fedora 20.
* Add support for packaging Go apps.
* Add support for installing cron files automatically.
* Allow to output a compressed version of the compile cache.
* Update ruby buildpack to use universal branch of https://github.com/pkgr/heroku-buildpack-ruby.
* Preliminary support for installer wizards. New configure and reconfigure CLI commands.

## 1.3.2 - 20140527

* Added more relaxed curl timeouts for Ubuntu Trusty ruby buildpack.

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
