#!/usr/bin/env bash

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
[ -f /etc/${APP_NAME}/conf.d/other ] || cat  > /etc/${APP_NAME}/conf.d/other <<CONF
# This file contains variables set via \`${APP_NAME} config:set\`
# Database URL. E.g. : mysql2://root:pass@127.0.0.1/my-app-db
export DATABASE_URL=db_adapter://db_user:db_password@db_host/db_name
export PORT=\${PORT:=6000}
CONF

chown -R ${APP_USER}.${APP_GROUP} /etc/${APP_NAME}

chmod 0750 /etc/${APP_NAME} /etc/${APP_NAME}/conf.d
find /etc/${APP_NAME} -type f -exec chmod 0640 {} +

<% if after_install && File.readable?(after_install) %>
# Call custom postinstall script.
CUSTOM_POSTINSTALL_SCRIPT="<%= Base64.encode64 File.read(after_install) %>"

tmpfile=$(mktemp)
chmod a+x "${tmpfile}"
echo "${CUSTOM_POSTINSTALL_SCRIPT}" | base64 -d - > ${tmpfile}

"${tmpfile}" "$@"
<% end %>
