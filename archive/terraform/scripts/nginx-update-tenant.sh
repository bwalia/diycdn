#!/bin/bash

set -x

FILE="/tmp/nginx-update-tenant.txt"
if [ -f "$FILE" ]; then
/usr/local/openresty/bin/openresty -t && systemctl restart openresty.service
rm -Rf ${FILE}
else
echo "${FILE} does not exist."
fi