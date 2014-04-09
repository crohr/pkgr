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
