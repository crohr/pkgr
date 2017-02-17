#!/bin/bash

set -e

export APP_NAME="<%= name %>"
export APP_USER="<%= user %>"
export APP_GROUP="<%= group %>"
export APP_HOME="<%= home %>"

<% crons.each do |cron| %>
# delete cron if original file no longer exists
if [ ! -f <%= cron.source %> ] ; then
  rm -f <%= cron.destination %>
fi
<% end %>

<% if after_remove && File.readable?(after_remove) %>
# Call custom postuninstall script.
CUSTOM_POSTUNINSTALL_SCRIPT="<%= Base64.encode64 File.read(after_remove) %>"

<%= "tmpfile=$(#{"TMPDIR=\"#{tmpdir}\" " if tmpdir}mktemp)" %>
chmod a+x "${tmpfile}"
echo "${CUSTOM_POSTUNINSTALL_SCRIPT}" | base64 -d - > ${tmpfile}

"${tmpfile}" "$@"
<% end %>
