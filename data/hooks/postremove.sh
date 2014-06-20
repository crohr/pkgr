#!/usr/bin/env bash

set -e

export APP_NAME="<%= name %>"
export APP_USER="<%= user %>"
export APP_GROUP="<%= group %>"
export APP_HOME="<%= home %>"

if ! getent passwd "${APP_USER}" > /dev/null; then
  if [ -f /etc/redhat-release ]; then
    adduser "${APP_USER}" --user-group --system --create-home --shell /bin/bash
  else
    adduser "${APP_USER}" --disabled-login --group --system --quiet --shell /bin/bash
  fi
fi

<% if after_remove && File.readable?(after_remove) %>
# Call custom postremove script. The package will not yet be unpacked, so the
# postinst script cannot rely on any files included in its package.
# https://www.debian.org/doc/debian-policy/ch-maintainerscripts.html
CUSTOM_POSTREMOVE_SCRIPT="<%= Base64.encode64 File.read(after_remove) %>"

tmpfile=$(mktemp)
chmod a+x "${tmpfile}"
echo "${CUSTOM_POSTREMOVE_SCRIPT}" | base64 -d - > ${tmpfile}

"${tmpfile}" "$@"
<% end %>
