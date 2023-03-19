#!/bin/bash

set -x

/usr/local/openresty/bin/openresty -t && systemctl restart openresty.service

FILE="/var/nginx/nginx.pid"

mkdir -p /var/nginx/
touch $FILE
chmod 777 $FILE
chmod +x $FILE
chown ec2-user:root $FILE

# TERM, INT	Quick shutdown
# QUIT	Graceful shutdown
# KILL	Halts a stubborn process
# HUP	Configuration reload & Start the new worker processes with a new configuration & Gracefully shutdown the old worker processes
# USR1	Reopen the log files
# USR2	Upgrade Executable on the fly
# WINCH	Gracefully shutdown the worker processes

SIGNAL="HUP"

NGINX_PROC_ID=$(ps -ef | grep 'nginx: master process /usr/local/openresty/bin/openresty' | head -1 | awk '{print $2}')
echo $NGINX_PROC_ID
/bin/kill -$SIGNAL $NGINX_PROC_ID

if test -f "$FILE"; then
cat /var/nginx/nginx.pid
fi