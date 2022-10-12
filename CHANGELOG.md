## master

- Pass APP_PKG_VERSION and APP_PKG_ITERATION during compilation step

## 1.9.0

- add support for Ubuntu 22.04
- create crons dir if missing
- update nodejs buildpack to v197
- upgrade ruby buildpack
- add --no-gpg-checks for SLES11 and SLES12 when setting up **build** dependencies. This is suboptimal, but helps with outdated package repos.

## 1.8.0

- Publish docker images to simplify build
- Upgrade ruby buildpack to v227-1
- Improve log file display

## 1.7.3

- Add support for Ubuntu 20.04
- Update ruby buildpack to v212-1

## 1.7.2

- Add support for RHEL 8.
- Update ruby buildpack to v206-1. Supports Rails6.
- Add support for Debian 10 "buster"
- Add `config:unset` to CLI.
- Update ruby buildpack to v199-1. Supports bundler2.

## 1.7.1

- Work around bundler requiring a writable home dir for executing bundle install

## 1.7.0

- Ubuntu 18.04
- Ruby buildpack v183-1

## 1.6.0

- Handle both opt/ logs and systemd logs
- Support for debian 9
- Support for configuring app environment through `cat env-file | my-app configure`
- Running `my-app configure` will try to run a configure script if one found in `packaging/scripts/configure`
- Introduction of `my-app restart [process]` command, to abstract differences among init systems
- `my-app logs` now forwards to journalctl, on systemd-enabled distributions
- Lots of fixes and improvements as to how PORTs are defined
  - Interactive runs properly handle PORT given on command line, e.g. `PORT=xxx my-app run web`
  - A PORT is now assigned for each Procfile process, offset by 100 from base PORT for each process type
  - Each worker of a specific process type is assigned a PORT equal to BASE_PORT+PORT_OFFSET+WORKER_INDEX-1
  - Existing PORT configuration is not touched for backwards compatibility (you only get the new configuration when running the `scale` command).
- Permit specifying multiple buildpacks to execute
- Upgrade default ruby and nodejs buildpacks to v164 and v104
- Fix runtime postgres dependency for sles12
- Add home parameter in CLI
- Do not attempt to create /usr/bin if CLI disabled
- Ensure existence of the logs directory
- Travis updates and build status image

## 1.5.1 - 20160908

- Update Ruby buildpack URL to get the latest ruby versions asutomatically
- Add support for Python!

## 1.5.0 - 20160908

- Fix upstart job for CentOS
- Reinstall master and process master init scripts whenever scale is called
- Run chroot with the user's configured groups
- Add SLES11 support
- Fix postinstall shebang
- Can now disable default dependencies with `default_dependencies: false`
- Allow to override `data_dir` folder
- Generate init files with correct PORT
- Allow hard-coded defaults to be overridden by pkgr.yml
- Pass ENV_DIR to compile script
- Replace only instances of `/app/` and not `/app` in buildpacks
- Create /app dir, which is required by some buildpacks to compile (e.g. GO)
- Pass TARGET as an env variable when compiling, so that it can be used to fetch binaries from buildcurl.com
- Add possibility to set category and directories fpm option
- Support for Ubuntu 16.04
- Add command-line flags for disabling default dependencies and CLI

## 1.4.4 - 20150512

- Add CentOS / RHEL 7 support with systemd
- Add Debian 8 "jessie" support with systemd
- Upstart: make sure to start once filesystem is up
- Add Amazon Linux 2015 support
- Allow addons to be installed from a local relative path
- Add SLES12 support
- Extract SVN version number, if available
- Changed interpreter in maintainer scripts to /bin/bash in order to avoid forbidden-postrm-interpreter errors on Debian 7

## 1.4.3 - 20150304

- Allow to run some commands as the APP_USER instead of root
- Some profile.d scripts output stuff (e.g. newest nodejs buildpack), so redirect to /dev/null

## 1.4.2 - 20150227

- Use Shellwords to escape command line args
- Allow scaledowns to finish even if stopping the service does not work
- Retry the packaging command at most 3 times if the package verification failed
- Add CLI options for `--before-remove` and `--after-remove` scripts
- Make sure `.git` directories are not included in the resulting package

## 1.4.1 - 20150217

- Allow to set config variables with equal signs in their values
- Add --vendor option
- Add net-tools to dependencies when using installer
- Add which to dependencies when using installer
- Add support for SLES12 (rpm)
- Get remote compiling working
- All processes from Procfile are now exported as potential services
- Add option to verify the generated packages
- CLI support: allow to overwrite default CLI to point to custom executable

## 1.4.0 - 20141015

- Add support for Fedora 20.
- Add support for packaging Go apps.
- Add support for installing cron files automatically.
- Allow to output a compressed version of the compile cache.
- Update ruby buildpack to use universal branch of https://github.com/pkgr/heroku-buildpack-ruby.
- Preliminary support for installer wizards. New configure and reconfigure CLI commands.

## 1.3.2 - 20140527

- Added more relaxed curl timeouts for Ubuntu Trusty ruby buildpack.

## 1.3.1 - 20140506

- Add buildpacks for Ubuntu 14.04.
- Add support for pre/post install files.

## 1.3.0 - 20140502

- CLI: Support for Ubuntu Trusty 14.04
- Put the CLI in /usr/bin.
- Properly set HOME environment variable to /home/:user
- Add more relaxed timeouts on ruby buildpacks.
- Add PROCESS_MANAGER env variable if custom runner is forced.
- Fix issues with .pkgr.yml custom runner not being picked up
- Allow to force a custom runner (upstart, sysvinit).
- Handles termination of processes that fork upon starting.
- Fix sysvinit script.
- Fix permissions on /etc/appname.
- Fix dependencies installation.
- Make user:group the owner of /etc/appname/\*
- Add tests for CLI
- CentOS experimental support
- Added --after-precompile and --license options.
- Move slow test to integration.
- Outputs buildpack cloning step.

## 1.2.0 - 20140409

- Add --buildpack-list option, with support for environment variables to be given to a buildpack.
- Reduce list of builtin buildpacks to Ruby and NodeJS.
- Remove upstart dependency.
- Add sysvinit support for debian distros.
- Fix PORT_NUM substitution.
- Allow to set a maintainer for the package.
- Rescue more errors, for better display.
- Add debug output when launching buildpack compile command.

## 1.1.8 - 20140326

- Fix master init script.
- Allow after hooks.

## 1.1.7 - 20140325

- Expand given path when packaging.

## 1.1.6 - 20140320

- Correctly export environment variables in /etc/default/your-app.
