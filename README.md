# pkgr

## Goal

Make debian packages out of any app that can run on Heroku.

## Examples

* Gitlab package for debian wheezy: <http://deb.pkgr.io/crohr/gitlabhq/>.

## Installation

Note: the new version of pkgr using buildpacks is only available as a pre-release.

Install `pkgr` on a Debian/Ubuntu machine (only `wheezy` flavour for now):

    sudo apt-get install ruby1.9.1-full
    sudo gem install pkgr --version "1.0.1.pre"

## Usage

To package your app, you can either execute `pkgr` locally if your app repository is on the same machine:

    pkgr path/to/app/repo

Or, assuming your build machine is accessible via SSH by doing `ssh pkgr-build-machine` (set this in your `~/.ssh/config` file), you can do as follows:

    pkgr path/to/app/repo --host pkgr-build-machine

The resulting .deb package will be in your current working directory.

Full command line options are given below:

    $ pkgr help package
    Usage:
      pkgr package TARBALL

    Options:
      [--target=TARGET]                        # Target package to build (only 'deb' supported for now)
                                               # Default: deb
      [--changelog=CHANGELOG]                  # Changelog
      [--architecture=ARCHITECTURE]            # Target architecture for the package
                                               # Default: x86_64
      [--homepage=HOMEPAGE]                    # Project homepage
      [--description=DESCRIPTION]              # Project description
      [--version=VERSION]                      # Package version (if git directory given, it will use the latest git tag available)
      [--iteration=ITERATION]                  # Package iteration (you should keep the default here)
                                               # Default: 20131007132226
      [--user=USER]                            # User to run the app under (defaults to your app name)
      [--group=GROUP]                          # Group to run the app under (defaults to your app name)
      [--compile-cache-dir=COMPILE_CACHE_DIR]  # Where to store the files cached between packaging runs
      [--dependencies=one two three]           # Specific system dependencies that you want to install with the package
      [--build-dependencies=one two three]     # Specific system dependencies that must be present before building
      [--before-precompile=BEFORE_PRECOMPILE]  # Provide a script to run just before the buildpack compilation
      [--host=HOST]                            # Remote host to build on (default: local machine)
      [--auto]                                 # Automatically attempt to install missing dependencies
      [--verbose]                              # Run verbosely
      [--debug]                                # Run very verbosely
      [--name=NAME]                            # Application name (if directory given, it will default to the directory name)

## Why?

Tools such as [Capistrano](http://capify.org/) are great for deploying
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

* Uses Heroku buildpacks to embed all your dependencies within the debian package. That way, no need to mess with stale system dependencies, and no need to install anything by hand. Also, we get for free all the hard work done by Heroku developers to make sure your app runs fine in an isolated way.

* Gives you a nice executable, which closely replicates the Heroku toolbelt utility. For instance, assuming you're packaging an app called `my-app`, you can do the following:

        my-app config:set VAR=value
        my-app config:get VAR
        my-app run [procfile process] # e.g. my-app run rake db:migrate, my-app run console, etc.
        my-app scale web=1 worker=1
        ...

* You app will reside in `/opt/app-name`.

* You'll also get a upstart based initialization script that you can use directly.

* Logs will be stored in `/var/log/app-name/`, with a proper logrotate config automatically added.

* Config files can be added in `/etc/app-name/`

## Requirements

* You must have a Procfile.

* Your application must be Heroku compatible, meaning you should be able to set your main app's configuration via environment variables.

## Authors

* Cyril Rohr <cyril.rohr@gmail.com> - <http://crohr.me>

## Copyright

See LICENSE (MIT)
