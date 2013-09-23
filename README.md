# pkgr

## Goal

Make debian packages out of your Ruby and Rails apps.

## Examples

* Gitlab packages for debian wheezy and squeeze:
http://feedback.gitlab.com/forums/176466-general/suggestions/3649927-create-official-debian-packages

* Redmine

## How

Add `pkgr` to your Gemfile:

    gem 'pkgr'

Run bundler:

    bundle install

Get a machine running your linux distribution of choice (only `wheezy` and `squeeze` for now). Use vagrant or AWS or anything else. Let's assume you can access it by doing `ssh pkgr-build-machine` (we recommend adding an entry in your `~/.ssh/config` file for this):

    cd your/ruby/project
    bundle exec pkgr . --host=debian-host --output .
    # on host: get omnibus package with pkgr, ruby, etc.
    # run pkgr on directory, switch buildpack version based on /proc/version

## Why?

[Capistrano](http://capify.org/) is great for deploying Rails/Ruby
applications, but the deployment recipe can quickly become a mess, and scaling
the deployment to more than a few servers can prove to be difficult. Plus, if
you're already using automation tools such as
[Puppet](http://www.puppetlabs.com/) to configure your servers, you have to
run two different processes to configure your infrastructure.

Another issue with Capistrano is that the hook system is not that powerful.
Compare that with the pre/post-install/upgrade/uninstall steps that you can
define in a RPM or DEB package, and you'll quickly see the advantage of
letting a robust package manager such as `apt` or `yum` handle all those
things for you in a reliable manner.

Last thing, once you built your RPM or DEB package and you tested that it
works once, you can deploy it on any number of servers at any time and you're
sure that it will install the required package dependencies, run the hooks,
and put the files in the directories you specified, creating them as needed.
Then, you can downgrade or uninstall the whole application in one command.

## What you'll end up with

* an `init.d` script, based on your Procfile `web` entry, to easily start/stop/restart your app, and make it load when the server boots;

* an executable to manually start the server, your rake tasks, or access the console;

* your configuration files will be available in `/etc/app-name/*.yml`;

* defaults for your app (host, port, etc.) can be setup in `/etc/default/app-name`;

* a proper `logrotate` file will be created for you, so that your log files
  don't eat all the disk space of your server;

The default target installation directory for all the other app files will be
`/opt/local/app-name`. This can be configured.

## Requirements

* You must have a Procfile (TODO: ref to heroku doc).

* Your application must be checked into a **Git** repository. Your name and
  email is taken from the git configuration, and the changelog is populated
  based on the git log between two versions.

## Development

Install pkgr dependencies:

    bundle install
    bundle exec rake

Generate pkgr native packages with:

    cd omnibus-pkgr/
    vagrant up ubuntu-12.04 && vagrant up ubuntu-10.04
    ls -al pkgr/

## Authors

* Cyril Rohr <cyril.rohr@gmail.com> - <http://crohr.me>

## Copyright

See LICENSE (MIT)
