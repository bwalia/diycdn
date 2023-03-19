#!/bin/bash

set -x
SSH_USER="ec2-user"

amazon-linux-extras install epel -y
yum install gcc jemalloc-devel openssl-devel tcl tcl-devel -y
wget http://download.redis.io/redis-stable.tar.gz
tar xvzf redis-stable.tar.gz
cd redis-stable
    #make BUILD_TLS=yes
gmake && gmake install

FILE="/home/${SSH_USER}/redis-stable/redis.conf"
if [ -f "$FILE" ]; then
mv $FILE /etc/redis.conf
fi

FILE="/tmp/redis.conf"
if [ -f "$FILE" ]; then
mv $FILE /etc/redis.conf
fi

# Set variables 
FILE="/tmp/redis.service"
if [ -f "$FILE" ]; then
mv $FILE /etc/systemd/system/redis.service
FILE=/etc/systemd/system/redis.service
chown root:root /etc/systemd/redis.service
fi

if [ -f "$FILE" ]; then
systemctl daemon-reload
systemctl enable redis.service
systemctl start redis.service
systemctl status redis.service
fi

FILE="/run/redis.sock"
if [ -f "$FILE" ]; then
chown ${SSH_USER}:${SSH_USER} /run/redis.sock
chmod 777 -R $FILE
fi