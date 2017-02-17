#!/bin/bash

set -e

export APP_NAME="<%= name %>"
export APP_USER="<%= user %>"
export APP_GROUP="<%= group %>"
export APP_HOME="<%= home %>"

<% if before_remove && File.readable?(before_remove) %>
CUSTOM_PREUNINSTALL_SCRIPT="<%= Base64.encode64 File.read(before_remove) %>"

<%= "tmpfile=$(#{"TMPDIR=\"#{tmpdir}\" " if tmpdir}mktemp)" %>
chmod a+x "${tmpfile}"
echo "${CUSTOM_PREUNINSTALL_SCRIPT}" | base64 -d - > ${tmpfile}

"${tmpfile}" "$@"
<% end %>
