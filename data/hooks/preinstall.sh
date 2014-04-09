#!/usr/bin/env bash

set -e

APP_USER="<%= user %>"

if ! getent passwd ${APP_USER} > /dev/null; then
  adduser ${APP_USER} --disabled-login --group --system --quiet --shell /bin/bash
fi
