#!/usr/bin/env bash

set -e

USER="<%= name %>"

if ! getent passwd ${USER} > /dev/null; then
  adduser ${USER} --disabled-login --system --quiet --shell /bin/bash
fi
