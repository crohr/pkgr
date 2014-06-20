#!/usr/bin/env bash


<% if after_remove && File.readable?(after_remove) %>
# Call custom postremove script.
CUSTOM_POSTREMOVE_SCRIPT="<%= Base64.encode64 File.read(after_remove) %>"

tmpfile=$(mktemp)
chmod a+x "${tmpfile}"
echo "${CUSTOM_POSTREMOVE_SCRIPT}" | base64 -d - > ${tmpfile}

"${tmpfile}" "$@"
<% end %>
