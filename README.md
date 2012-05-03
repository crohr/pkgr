# pkgr

Plug this [Railtie](http://api.rubyonrails.org/classes/Rails/Railtie.html) into your Rails 3 app (ruby1.9 only), and you'll be ready to package your Rails app as a DEB or RPM package.

## Why?

[Capistrano](http://capify.org/) is great for deploying Rails/Ruby applications, but the deployment recipe can quickly become a mess, and scaling the deployment to more than a few servers can prove to be difficult. Plus, if you're already using automation tools such as [Puppet](http://www.puppetlabs.com/) to configure your servers, you have to run two different processes to configure your infrastructure.

Another issue with Capistrano is that the hook system is not that powerful. Compare that with the pre/post-install/upgrade/uninstall steps that you can define in a RPM or DEB package, and you'll quickly see the advantage of letting a robust package manager such as `apt` or `yum` handle all those things for you in a reliable manner.

Last thing, once you built your RPM or DEB package and you tested that it works once, you can deploy it on any number of servers at any time and you're sure that it will install the required package dependencies, run the hooks, and put the files in the directories you specified, creating them as needed.
Then, you can downgrade or uninstall the whole application in one command.

## How?

The issue with Ruby applications is that most of the gems are not (yet) packaged in the various Linux distributions. And even if they were, installing multiple Ruby applications that need two different versions of the same Ruby library would be impossible, since you can't install two different (minor) versions of a library with the package managers.

So, how are we going to easily package Ruby applications and avoid dependency issues? Well, I know package maintainers will scream at me, but we'll just vendor the required gems in the package we'll build, and use bundler to manage those dependencies. Thus, the only dependency we'll put in our package will be the Ruby1.9 (+rubygems).

## What?

This gem will allow you to package your Rails3 application, create an `init.d` script for you, install a binary file to start your app/rake tasks/console, put your configuration files in `/etc/app-name/`, and a few other things.

The default target installation directory for the other app files will be `/opt/local/app-name`. This can be configured.

## Usage

Declare the `rails-packager` as one of your dependencies in your `Gemfile`:

    gem 'rails-packager'

TODO: explain how to configure the Railtie, add dependencies.

This gem will add a number of rake tasks to handle packaging tasks:

    # set package version
    rake package:bump:patch
    rake package:bump:minor
    rake package:bump:major
    rake package:bump:custom VERSION="x.y.z"

    # build package
    rake package:rpm:build TARGET='localhost'
    rake package:deb:build TARGET='debian-build'

    # install package
    rake package:rpm:install TARGET='centos-test'
    rake package:deb:install TARGET='localhost'

    # generate package repository
    TODO

## Requirements

* You must use Rails3+ and ruby1.9+ in your application. This may work with other rubies but then you'll need to add a rubygems dependency.
* Your Rails application must be able to run with the [`thin`](http://code.macournoyer.com/thin/) web server.

## Authors

* Cyril Rohr <cyril.rohr@gmail.com>

## Copyright

See LICENSE (MIT)
