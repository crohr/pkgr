#!/bin/bash

set -e

export APP_NAME="<%= name %>"
export APP_USER="<%= user %>"
export APP_GROUP="<%= group %>"
export APP_HOME="<%= home %>"

HOME_LOGS="${APP_HOME}/log"
LOGS="/var/log/${APP_NAME}"

chown -R ${APP_USER}.${APP_GROUP} ${APP_HOME}

# link app log directory to /var/log/NAME
rm -rf ${HOME_LOGS}
ln -fs ${LOGS} ${HOME_LOGS}
chown -R ${APP_USER}.${APP_GROUP} ${LOGS}

# Add default conf.d file
[ -f /etc/${APP_NAME}/conf.d/other ] || touch /etc/${APP_NAME}/conf.d/other

chown -R ${APP_USER}.${APP_GROUP} /etc/${APP_NAME}
chown ${APP_USER}.${APP_GROUP} /var/db/${APP_NAME}

chmod 0750 /etc/${APP_NAME} /etc/${APP_NAME}/conf.d
find /etc/${APP_NAME} -type f -exec chmod 0640 {} +

<% crons.each do |cron| %>
rm -f <%= cron.destination %>
cp <%= cron.source %> <%= cron.destination %>
chmod 0640 <%= cron.destination %>
<% end %>

<% if installer %>
echo "=============="
echo "The ${APP_NAME} package provides an installer. Please run the following command to finish the installation:"
echo "sudo ${APP_NAME} configure"
echo "=============="
<% end %>

<% if after_install && File.readable?(after_install) %>
# Call custom postinstall script.
CUSTOM_POSTINSTALL_SCRIPT="<%= Base64.encode64 File.read(after_install) %>"

tmpfile=$(mktemp)
chmod a+x "${tmpfile}"
echo "${CUSTOM_POSTINSTALL_SCRIPT}" | base64 -d - > ${tmpfile}

"${tmpfile}" "$@"
<% end %>
