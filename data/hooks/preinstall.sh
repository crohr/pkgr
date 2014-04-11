#!/usr/bin/env bash

set -e

APP_USER="<%= user %>"

if ! getent passwd "${APP_USER}" > /dev/null; then
  if [ -f /etc/redhat-release ]; then
    adduser "${APP_USER}" --user-group --system --create-home --shell /bin/bash
  else
    adduser "${APP_USER}" --disabled-login --group --system --quiet --shell /bin/bash
  fi
fi
