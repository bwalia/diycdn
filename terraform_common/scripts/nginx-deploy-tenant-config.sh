#!/bin/bash

set -x

TENANTS_CONFIG_DIR=/opt/nginx/conf/nginx-tenants.d/
SCRIPTS_DEST_DIR="/opt/nginx/scripts/"

mv -f /tmp/*.conf ${TENANTS_CONFIG_DIR}

/bin/bash ${SCRIPTS_DEST_DIR}nginx-configtest.sh
/bin/bash ${SCRIPTS_DEST_DIR}nginx-reload.sh