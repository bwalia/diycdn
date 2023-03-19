#!/bin/bash

set -x

TENANTS_ROOT_DIR="/usr/local/openresty/nginx/"
NGINX_HTML_DIR="${TENANTS_ROOT_DIR}html/"


mkdir -p ${NGINX_HTML_DIR}
#mv -f /tmp/nginx/html/* ${NGINX_HTML_DIR}
cp -r /tmp/nginx/html/* ${NGINX_HTML_DIR}
