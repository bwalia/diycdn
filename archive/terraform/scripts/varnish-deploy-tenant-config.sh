#!/bin/bash

set -x

TENANTS_CONFIG_DIR=/opt/varnish/conf/nginx-varnish.d/
SCRIPTS_DEST_DIR="/opt/varnish/scripts/"

mv -f /tmp/*.conf ${TENANTS_CONFIG_DIR}

/bin/bash ${SCRIPTS_DEST_DIR}varnish-configtest.sh
/bin/bash ${SCRIPTS_DEST_DIR}varnish-reload.sh