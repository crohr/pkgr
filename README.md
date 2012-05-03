# pkgr

Plug this [Railtie](http://api.rubyonrails.org/classes/Rails/Railtie.html)
into your Rails 3 app (ruby1.9 only), and you'll be ready to package your
Rails app as a DEB or RPM (coming soon) package.

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

## How?

The issue with Ruby applications is that most of the gems are not (yet)
packaged in the various Linux distributions. And even if they were, installing
multiple Ruby applications that need two different versions of the same Ruby
library would be impossible, since you can't install two different (minor)
versions of a library with the package managers.

So, how are we going to easily package Ruby applications and avoid dependency
issues? Well, I know package maintainers will scream at me, but we'll just
vendor the required gems in the package we'll build, and use bundler to manage
those dependencies. Thus, the only dependency we'll put in our package will be
the Ruby1.9 (+rubygems).

## What?

This gem will allow you to package your Rails3 application, create an `init.d`
script for you, install a binary file to start your app/rake tasks/console,
put your configuration files in `/etc/app-name/`, setup a proper logrotate
file so that your log files don't eat all the disk space of your server, and a
few other things.

The default target installation directory for the other app files will be
`/opt/local/app-name`. This can be configured.

## Usage

Declare `pkgr` as one of your **development** dependencies in your `Gemfile`:

    group :development do
      gem 'pkgr'
    end

Now make sure you have all the gems installed:

    bundle install

`pkgr` will install a number of new rake tasks to handle the packaging
workflow. But first, you'll have to create a configuration file to get it
working:

    rake pkgr:setup

This will create a configuration file at `config/pkgr.yml`. Edit it, and fill
in details about the `name` of your application, description, and the list of
runtime dependencies it depends on. Same for dependencies required at build
time only (most of the time, development headers).

Now you can generate all the files required for building a debian package:

    rake pkgr:generate

A new directory `debian/` should have been created. You can have a look at it,
but you should not have to edit anything manually.

Once you're ready to package your app, just run the following steps:

* Increment the version number:

        rake pkgr:bump:patch # or rake pkgr:bump:minor or rake pkgr:bump:major

* Re-generate the debian files:

        rake pkgr:generate

* Commit your changes (the `pkgr` app will `git archive HEAD`, which means all
  your changes must be committed first -- we may want to change this):

        commit -am "..."

* Build the package on your machine (default, but you better be running a
  Debian Squeeze), or on a remote machine (recommended, for instance you can
  get a Vagrant VM in no time):

        HOST=debian-build-machine rake pkgr:build:deb
        # or HOST=localhost rake pkgr:build:deb, or just rake pkgr:build:deb

  Note that the user with which you're connecting to the build machine **must
  have `sudo` privileges** (required to install build and runtime
  dependencies).

  Also, it's most likely that you'll have to do this a few times at first, as
  well as adding missing runtime and build dependencies, before your app can
  be successfully packaged.

* Your .deb package should be made available in the `pkg` directory of your
  app. Next step is probably to upload it to a local apt repository, and then
  a simple `apt-get install my-app` will install everything. Enjoy!



## Requirements

* You must use Rails3+ and ruby1.9+ in your application. This may work with
  other rubies but then you'll need to add a rubygems dependency.

* Your Rails application must be able to run with the
  [`thin`](http://code.macournoyer.com/thin/) web server. Don't forget to add
  `thin` to your Gemfile!

* Your application must be checked into a **Git** repository. Your name and
  email is taken from the git configuration, and the changelog is populated
  based on the git log between two versions.

## TODO

* Speed up the packaging process (currently, bundler re-downloads all the gems
  each time you package an app).

* Include tasks for building RPMs.

* Better debian initd script.

* Some tests.

## Authors

* Cyril Rohr <cyril.rohr@gmail.com> - <http://crohr.me>

## Copyright

See LICENSE (MIT)
