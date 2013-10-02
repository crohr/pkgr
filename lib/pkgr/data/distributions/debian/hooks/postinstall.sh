#!/usr/bin/env bash

set -e

APP_USER="<%= user %>"
APP_GROUP="<%= group %>"
HOME="/opt/<%= name %>"
HOME_LOGS="${HOME}/log"
LOGS="/var/log/<%= name %>"

chown -R ${APP_USER}.${APP_GROUP} ${HOME}
# link app log directory to /var/log/NAME
rm -rf ${HOME_LOGS}
ln -fs ${LOGS} ${HOME_LOGS}
chown -R ${APP_USER}.${APP_GROUP} ${LOGS}
