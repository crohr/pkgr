# pkgr

Plug this [Railtie](http://api.rubyonrails.org/classes/Rails/Railtie.html)
into your Rails 3 app (ruby1.9 only), and you'll be ready to package your
Rails app as a DEB package. RPM support could be added in the short future.

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

## Getting started

Or, how to build a debian package of your Rails app in 5 minutes.

### Setup

Create a new Rails app:

    $ rails new my-app --skip-bundle
          create  
          create  README.rdoc
          create  Rakefile
          ...
          create  vendor/plugins
          create  vendor/plugins/.gitkeep

Go into your app directory, and add `pkgr` to your Gemfile:

    $ cd my-app
    $ echo "gem 'pkgr', :group => :development" >> Gemfile

For now, this packaging tool only supports `thin` (would be easy to add others, though), so add it to your Gemfile:

    $ echo "gem 'thin'" >> Gemfile

Install the gems:

    $ bundle install

If it's not already done, initialize a git repository and create a first commit:

    $ git init
    $ git add .
    $ git commit -m "First commit"

Setup `pkgr`:

    $ rake pkgr:setup
    Setting up configuration file...
    ...
    Edit '/Users/crohr/tmp/my-app/config/pkgr.yml' and fill in the required information, then enter 'rake pkgr:generate' to generate the debian files.

As outlined, edit `config/pkgr.yml` and fill in your app name. In our example I'll fill in `my-app` as the app name. Also, you should edit the runtime and build dependencies (though the default ones should be fine with a base Rails app).

### Generate the packaging files

Now generate the required files for packaging:

    $ rake pkgr:generate
    mkdir -p /Users/crohr/tmp/my-app/debian
    cp /Users/crohr/.rvm/gems/ruby-1.9.3-p125/gems/pkgr-0.1.0/lib/pkgr/data/debian/changelog /Users/crohr/tmp/my-app/debian/changelog
    cp /Users/crohr/.rvm/gems/ruby-1.9.3-p125/gems/pkgr-0.1.0/lib/pkgr/data/debian/cron.d /Users/crohr/tmp/my-app/debian/cron.d
    Correctly set up debian files.
    mkdir -p /Users/crohr/tmp/my-app/bin
    cp /Users/crohr/.rvm/gems/ruby-1.9.3-p125/gems/pkgr-0.1.0/lib/pkgr/data/bin/executable /Users/crohr/tmp/my-app/bin/my-app
    chmod 755 /Users/crohr/tmp/my-app/bin/my-app
    Correctly set up executable file. Try running './bin/my-app console'.

This will have created the required `debian/` files, plus an executable for your app, so that you're able to do the following:

    $ ./bin/my-app console development
    $ ./bin/my-app server start -e development
    $ ./bin/my-app rake some_task

This is especially useful when the app is deployed on a server, since the executable will be added to the path!

By default, you should not have to change anything in the `debian/` folder, so let's package our app. 

### Package the app

First, make sure you committed all your changes:

    $ git add .
    $ git commit -m "..."

Then increase the version number:

    $ rake pkgr:bump:minor
    Committing changelog and version file...
    git add debian/changelog /Users/crohr/tmp/my-app/config/pkgr.yml && git commit -m 'v0.1.0' debian/changelog /Users/crohr/tmp/my-app/config/pkgr.yml
    [master c05dd73] v0.1.0
     2 files changed, 29 insertions(+), 31 deletions(-)
     rewrite config/pkgr.yml (82%)
     create mode 100755 debian/changelog

Make sure you do not have any staged change (otherwise, commit them):

    $ git status
    # On branch master
    nothing to commit (working directory clean)

Finally, ask to build the package on a machine running Debian Squeeze (I generally use my SSH config file to handle the SSH connection details for the specified host):

    $ HOST=debian-build-machine rake pkgr:build:deb

After some time, you should get a final line with the name of your debian package:

    [... lots of lines ...]
    my-app_0.1.0-1_amd64.deb

Make sure it is really here:

    $ ls -l pkg/
    total 12128
    -rw-r--r--  1 crohr  staff  6207392 May  4 10:57 my-app_0.1.0-1_amd64.deb

### Use it

Now you can either upload it to an apt repository (if you have one, I'll make a tutorial on how to set up a simple one), or just test that the package works by installing it on your build machine (or another one, for that matter, but you'll have to manually re-install the dependencies):

    $ scp pkg/my-app_0.1.0-1_amd64.deb debian-build-machine:/tmp/
    $ ssh debian-build-machine
    debian-build-machine $ sudo dpkg -i /tmp/my-app_0.1.0-1_amd64.deb
    Selecting previously deselected package my-app.
    (Reading database ... 53073 files and directories currently installed.)
    Unpacking my-app (from /tmp/my-app_0.1.0-1_amd64.deb) ...
    Setting up my-app (0.1.0-1) ...
    Installing new version of config file /etc/my-app/pkgr.yml ...
    Adding system user `my-app' (UID 105) ...
    Adding new group `my-app' (GID 108) ...
    Adding new user `my-app' (UID 105) with group `my-app' ...
    Not creating home directory `/home/my-app'.
    Starting my-app: OK.

Make sure your app is running:

    debian-build-machine $ ps aux | grep my-app | grep -v grep
    my-app   13928  3.5 10.5 143436 40004 ?        Sl   11:06   0:02 thin server (0.0.0.0:8000) [my-app-0.1.0]

Notice how the process name shows the version number? From experience, this is really useful.

Now you can send a first request:

    $ curl localhost:8000/
    <!DOCTYPE html>
    <html>
    <head>
      <title>The page you were looking for doesn't exist (404)</title>
      <style type="text/css">
        body { background-color: #fff; color: #666; text-align: center; font-family: arial, sans-serif; }
        div.dialog {
          width: 25em;
          padding: 0 4em;
          margin: 4em auto 0 auto;
          border: 1px solid #ccc;
          border-right-color: #999;
          border-bottom-color: #999;
        }
        h1 { font-size: 100%; color: #f00; line-height: 1.5em; }
      </style>
    </head>

    <body>
      <!-- This file lives in public/404.html -->
      <div class="dialog">
        <h1>The page you were looking for doesn't exist.</h1>
        <p>You may have mistyped the address or the page may have moved.</p>
      </div>
    </body>
    </html>

Obviously this app does nothing, so you'll get a 404. So go back to building your app, and then just type `rake pkgr:bump:path` and `HOST=debian-build-machine rake pkgr:build:deb` to generate a new package !

## Notes of interest

* your configuration files will be stored in `/etc/my-app/*.yml`, making it easy to manage with Puppet or manually (don't forget to `/etc/init.d/my-app restart` after making changes).

* you can change how the Thin server is launched by adding options to the `/etc/default/my-app` file.

* your log files will be stored in `/var/log/my-app/`.

* your db files will be stored in `var/db/my-app/`.

* if you've got migrations to run, just do a `my-app rake db:migrate` (we might want to run them automatically as part of the postinstall process).

* you can launch a console using `my-app console`.

* use the initd script to start and stop the app: `/etc/init.d/my-app [start|stop|status]`.

## General usage

Declare `pkgr` as one of your **development** dependencies in your `Gemfile`:

    gem 'pkgr', :group => :development

Also add `thin`:

    gem 'thin'

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

Once you're ready to package your app, just run the following commands:

* Commit your changes (the `pkgr` app will `git archive HEAD`, which means all
  your changes must be committed first -- we may want to change this):

        commit -am "..."

* Increment the version number:

        rake pkgr:bump:patch # or rake pkgr:bump:minor or rake pkgr:bump:major

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

## Todo

* Speed up the packaging process (currently, bundler re-downloads all the gems
  each time you package an app).

* Include tasks for building RPMs.

* Better debian initd script.

* Some tests.

## Authors

* Cyril Rohr <cyril.rohr@gmail.com> - <http://crohr.me>

## Copyright

See LICENSE (MIT)
