# pkgr

## Goal

Make debian or rpm packages out of any app, including init script, crons,
logrotate, etc. Excellent way to distribute apps or command line tools without
complicated installation instructions.

Hosted service available at <https://packager.io/>. Free for OpenSource apps.

## Officially supported languages

* Ruby
* NodeJS
* Python
* Go

You can also try out PHP support by specifying the following buildpack:
`https://github.com/pkgr/heroku-buildpack-php#buildcurl`

You can also point to other buildpacks
([doc](https://packager.io/documentation/customizing-the-build/#buildpack)).
They may just work.

## Supported distributions (64bits only)

* Ubuntu 16.04 ("xenial")
* Ubuntu 14.04 ("trusty")
* Ubuntu 12.04 ("precise")
* Debian 8 ("jessie")
* Debian 7 ("wheezy")
* RHEL/CentOS 7
* RHEL/CentOS 6
* Suse Linux Enterprise Server 12
* Suse Linux Enterprise Server 11
* Amazon Linux AMI 2015
* Amazon Linux AMI 2014

## Examples

See <https://packager.io/> for examples of apps packaged with `pkgr` (Gitlab, OpenProject, Discourse, etc.).

## Installation

You can find DEB and RPM packages for a wide range of distributions on Packager.io:

<https://packager.io/gh/crohr/pkgr>

Or, installing as a gem, on debian-based machines:

    sudo apt-get update
    sudo apt-get install -y build-essential ruby1.9.1-full rubygems1.9.1
    sudo gem install pkgr

## Usage

To package your app, you can either execute `pkgr` locally if your app repository is on the same machine:

    pkgr package path/to/app/repo

The resulting .deb package will be in your current working directory.

Full command line options are given below:

    $ pkgr help package
    Usage:
      pkgr package TARBALL|DIRECTORY

    Options:
      [--buildpack=BUILDPACK]                        # Custom buildpack to use
      [--buildpack-list=BUILDPACK_LIST]              # Specify a file containing a list of buildpacks to use (--buildpack takes precedence if given)
      [--changelog=CHANGELOG]                        # Changelog
      [--maintainer=MAINTAINER]                      # Maintainer
      [--vendor=VENDOR]                              # Package vendor
      [--architecture=ARCHITECTURE]                  # Target architecture for the package
                                                     # Default: x86_64
      [--runner=RUNNER]                              # Force a specific runner (e.g. upstart-1.5, sysv-lsb-1.3)
      [--homepage=HOMEPAGE]                          # Project homepage
      [--description=DESCRIPTION]                    # Project description
      [--category=CATEGORY]                          # Category this package belongs to
                                                     # Default: none
      [--version=VERSION]                            # Package version (if git directory given, it will use the latest git tag available)
      [--iteration=ITERATION]                        # Package iteration (you should keep the default here)
                                                     # Default: 20141015024539
      [--license=LICENSE]                            # The license of your package (see <https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/#license-short-name>)
      [--user=USER]                                  # User to run the app under (defaults to your app name)
      [--group=GROUP]                                # Group to run the app under (defaults to your app name)
      [--compile-cache-dir=COMPILE_CACHE_DIR]        # Where to store the files cached between packaging runs. Path will be resolved from the temporary code repository folder, so use absolute paths if needed.
      [--before-precompile=BEFORE_PRECOMPILE]        # Provide a script to run just before the buildpack compilation, on the build machine. Path will be resolved from the temporary code repository folder, so use absolute paths if needed.
      [--after-precompile=AFTER_PRECOMPILE]          # Provide a script to run just after the buildpack compilation, on the build machine. Path will be resolved from the temporary code repository folder, so use absolute paths if needed.
      [--before-install=BEFORE_INSTALL]              # Provide a script to run just before a package gets installated or updated, on the target machine.
      [--after-install=AFTER_INSTALL]                # Provide a script to run just after a package gets installated or updated, on the target machine.
      [--before-remove=BEFORE_REMOVE]                # Provide a script to run just before a package gets uninstallated, on the target machine.
      [--after-remove=AFTER_REMOVE]                  # Provide a script to run just after a package gets uninstallated, on the target machine.
      [--dependencies=one two three]                 # Specific system dependencies that you want to install with the package
      [--build-dependencies=one two three]           # Specific system dependencies that must be present before building
      [--host=HOST]                                  # Remote host to build on (default: local machine)
      [--auto], [--no-auto]                          # Automatically attempt to install missing dependencies
      [--clean], [--no-clean]                        # Automatically clean up temporary dirs
                                                     # Default: true
      [--edge], [--no-edge]                          # Always use the latest version of the buildpack if already installed
                                                     # Default: true
      [--env=one two three]                          # Specify environment variables for buildpack (--env "CURL_TIMEOUT=2" "BUNDLE_WITHOUT=development test")
      [--force-os=FORCE_OS]                          # Force a specific distribution to build for (e.g. --force-os "ubuntu-12.04"). This may result in a broken package.
      [--store-cache], [--no-store-cache]            # Output a tarball of the cache in the current directory (name: cache.tar.gz)
      [--verify], [--no-verify]                      # Verifies output package
                                                     # Default: true
      [--data-dir=DATA_DIR]                          # Custom path to data directory. Can be used for overriding default templates, hooks(pre-, post- scripts), configs (buildpacks, distro dependencies), environments, etc.
                                                     # Default: ./pkgr/data
      [--directories=DIRECTORIES]                    # Recursively mark a directory as being owned by the package
      [--verbose], [--no-verbose]                    # Run verbosely
      [--debug], [--no-debug]                        # Run very verbosely
      [--name=NAME]                                  # Application name (if directory given, it will default to the directory name)
      [--buildpacks-cache-dir=BUILDPACKS_CACHE_DIR]  # Directory where to store the buildpacks
                                                     # Default: /home/vagrant/.pkgr/buildpacks

## Why?

Tools such as [Capistrano](http://capistranorb.com/) are great for deploying
applications, but the deployment recipe can quickly become a mess, and scaling
the deployment to more than a few servers can prove to be difficult. Plus, if
you're already using automation tools such as
[Puppet](http://www.puppetlabs.com/) to configure your servers, you have to
run two different processes to configure your infrastructure.

`pkgr` builds on top of the Heroku tools to provide you with an easy way to package you app as a debian package. The great advantage is that once you've built it and you tested that it
works once, you can deploy on any number of servers at any time and you're
sure that it will just work. Then, you can upgrade/downgrade or uninstall the whole application in one command.

Finally, it's a great way to share your open source software with your users and clients. Much easier than asking them to install all the dependencies manually! I'm in the process of making sure `pkgr` is feature complete by trying to package as many successful open-source projects as I can. Don't hesitate to test it on your app and report your findings!

## What this does

* Uses Heroku buildpacks to embed all the dependencies related to your application runtime within the debian package. For a Rails app for instance, this means that `pkgr` will embed the specific ruby runtime you asked for, along with all the gems specified in your Gemfile. However, all other dependencies you may need must be specified as additional system dependencies (see Usage). This avoids the 'packaging-the-world' approach used by other tools such as omnibus (with the pros and cons that come with it), but it still allows you to use the latest and greatest libraries for your language of choice. See this [blog post][background-pkgr] for more background.

[background-pkgr]: http://blog.packager.io/post/81988994454/why-i-made-pkgr-io-digressions-on-software-packaging

* Gives you a nice executable, which closely replicates the Heroku toolbelt utility. For instance, assuming you're packaging an app called `my-app`, you can do the following:

        my-app config:set VAR=value
        my-app config:get VAR
        my-app run [procfile process] # e.g. my-app run rake db:migrate; my-app run console; etc.
        my-app run [arbitrary process] # e.g. my-app run ruby -v; my-app run bundle install; etc.
        my-app scale web=1 worker=1
        my-app logs [--tail]
        ...

* Your app will reside in `/opt/app-name`.

* You'll also get upstart (or sysvinit) initialization scripts that you can use directly:

        service my-app start/stop/restart/status

* Logs will be stored in `/var/log/app-name/`, with a proper logrotate config automatically added.

* Config files can be added in `/etc/app-name/`

## Requirements

* You must have a Procfile.

* Your application should be Heroku compatible, meaning you should be able to set your main app's configuration via environment variables.

## Troubleshooting

If you're on older versions of Debian, you may need to append `/var/lib/gems/1.9.1/bin` to your PATH to "see" the `pkgr` command:

    export PATH="$PATH:/var/lib/gems/1.9.1/bin"

If you get the following error `ERROR:  While executing gem ... (ArgumentError) invalid byte sequence in US-ASCII` while trying to install `pkgr`, try setting a proper locale, and then retry:

    sudo locale-gen en_US.UTF-8
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
    sudo gem install pkgr

Looking for the init script? It is created the first time you run this command

    sudo my-app scale web=1 worker=1

Issue getting nokogiri to compile? Try the following based on this [comment](https://github.com/crohr/pkgr/issues/60#issuecomment-96631181):

    bundle config --local build.nokogiri "--use-system-libraries --with-xml2-include=/usr/include/libxml2"

## Authors

* Cyril Rohr <cyril.rohr@gmail.com> - <http://crohr.me>, <https://packager.io>

## Copyright

See LICENSE (MIT)
