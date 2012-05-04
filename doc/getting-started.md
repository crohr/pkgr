# Build a debian package of your Rails app in 5 minutes

## Setup

Create a new Rails app:

    $ rails new my-app --skip-bundle
          create  
          create  README.rdoc
          create  Rakefile
          create  config.ru
          create  .gitignore
          create  Gemfile
          create  app
          create  app/assets/images/rails.png
          create  app/assets/javascripts/application.js
          create  app/assets/stylesheets/application.css
          create  app/controllers/application_controller.rb
          create  app/helpers/application_helper.rb
          create  app/mailers
          create  app/models
          create  app/views/layouts/application.html.erb
          create  app/mailers/.gitkeep
          create  app/models/.gitkeep
          create  config
          create  config/routes.rb
          create  config/application.rb
          create  config/environment.rb
          create  config/environments
          create  config/environments/development.rb
          create  config/environments/production.rb
          create  config/environments/test.rb
          create  config/initializers
          create  config/initializers/backtrace_silencers.rb
          create  config/initializers/inflections.rb
          create  config/initializers/mime_types.rb
          create  config/initializers/secret_token.rb
          create  config/initializers/session_store.rb
          create  config/initializers/wrap_parameters.rb
          create  config/locales
          create  config/locales/en.yml
          create  config/boot.rb
          create  config/database.yml
          create  db
          create  db/seeds.rb
          create  doc
          create  doc/README_FOR_APP
          create  lib
          create  lib/tasks
          create  lib/tasks/.gitkeep
          create  lib/assets
          create  lib/assets/.gitkeep
          create  log
          create  log/.gitkeep
          create  public
          create  public/404.html
          create  public/422.html
          create  public/500.html
          create  public/favicon.ico
          create  public/index.html
          create  public/robots.txt
          create  script
          create  script/rails
          create  test/fixtures
          create  test/fixtures/.gitkeep
          create  test/functional
          create  test/functional/.gitkeep
          create  test/integration
          create  test/integration/.gitkeep
          create  test/unit
          create  test/unit/.gitkeep
          create  test/performance/browsing_test.rb
          create  test/test_helper.rb
          create  tmp/cache
          create  tmp/cache/assets
          create  vendor/assets/javascripts
          create  vendor/assets/javascripts/.gitkeep
          create  vendor/assets/stylesheets
          create  vendor/assets/stylesheets/.gitkeep
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

## Generate the packaging files

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

## Package the app

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

## Use it

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
