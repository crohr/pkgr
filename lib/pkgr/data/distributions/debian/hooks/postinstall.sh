#!/usr/bin/env bash

set -e

APP_NAME="<%= name %>"
APP_USER="<%= user %>"
APP_GROUP="<%= group %>"
HOME="/opt/${APP_NAME}"
HOME_LOGS="${HOME}/log"
LOGS="/var/log/${APP_NAME}"

chown -R ${APP_USER}.${APP_GROUP} ${HOME}

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

chmod -R 0600 /etc/${APP_NAME}
