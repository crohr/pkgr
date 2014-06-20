#!/usr/bin/env bash

<% if before_remove && File.readable?(before_remove) %>

CUSTOM_PREREMOVE_SCRIPT="<%= Base64.encode64 File.read(before_remove) %>"

tmpfile=$(mktemp)
chmod a+x "${tmpfile}"
echo "${CUSTOM_PREREMOVE_SCRIPT}" | base64 -d - > ${tmpfile}

"${tmpfile}" "$@"
<% end %>
