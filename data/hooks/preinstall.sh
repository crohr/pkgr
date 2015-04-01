#!/bin/bash

set -e

export APP_NAME="<%= name %>"
export APP_USER="<%= user %>"
export APP_GROUP="<%= group %>"
export APP_HOME="<%= home %>"

if ! getent passwd "${APP_USER}" > /dev/null; then
  if [ -f /etc/redhat-release ] || [ -f /etc/system-release ] || [ -f /etc/SuSE-release ]; then
    if ! getent group "${APP_GROUP}" > /dev/null ; then
      groupadd --system "${APP_GROUP}"
    fi
    useradd "${APP_USER}" -g "${APP_GROUP}" --system --create-home --shell /bin/bash
  else
    if ! getent group "${APP_GROUP}" > /dev/null; then
      addgroup "${APP_GROUP}" --system --quiet
    fi
    adduser "${APP_USER}" --disabled-login --ingroup "${APP_GROUP}" --system --quiet --shell /bin/bash
  fi
fi

<% if before_install && File.readable?(before_install) %>
# Call custom preinstall script. The package will not yet be unpacked, so the
# preinst script cannot rely on any files included in its package.
# https://www.debian.org/doc/debian-policy/ch-maintainerscripts.html
CUSTOM_PREINSTALL_SCRIPT="<%= Base64.encode64 File.read(before_install) %>"

tmpfile=$(mktemp)
chmod a+x "${tmpfile}"
echo "${CUSTOM_PREINSTALL_SCRIPT}" | base64 -d - > ${tmpfile}

"${tmpfile}" "$@"
<% end %>
