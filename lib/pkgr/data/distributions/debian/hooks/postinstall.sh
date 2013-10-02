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

# Add default conf.d files
[ -f /etc/${APP_NAME}/conf.d/database ] || cat  > /etc/${APP_NAME}/conf.d/database <<CONF
# Database URL. E.g. : mysql2://root:pass@127.0.0.1/my-app-db
export DATABASE_URL=db_adapter://db_user:db_password@db_host/db_name
CONF

[ -f /etc/${APP_NAME}/conf.d/port ] || cat > /etc/${APP_NAME}/conf.d/port <<CONF
export PORT=${PORT:=6000}
CONF

chmod -R 0600 /etc/${APP_NAME}
