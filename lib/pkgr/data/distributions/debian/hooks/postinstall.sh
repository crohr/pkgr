#!/usr/bin/env bash

set -e

USER="<%= name %>"
HOME="/opt/<%= name %>"
HOME_LOGS="${HOME}/log"
LOGS="/var/log/<%= name %>"

chown -R ${USER} ${HOME}
# link app log directory to /var/log/NAME
rm -rf ${HOME_LOGS}
ln -fs ${LOGS} ${HOME_LOGS}
chown -R ${USER} ${LOGS}
