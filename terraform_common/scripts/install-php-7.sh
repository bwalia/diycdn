#!/bin/bash

set -x

# Download php src tar
#compile with modules
yum install sqlite-devel -y

#https://www.php.net/manual/en/install.unix.nginx.php

#https://www.php.net/distributions/php-7.4.22.tar.gz

mv /tmp/index.php /usr/local/openresty/nginx/html/index.php

#Add php unit file from templates dir onto target machine to /usr/lib/systemd/system/php-fpm.service
FILE="/tmp/php-fpm-7.service"

PID_FILE_DIR="/var/php/"
PHP_CONFIG_DIR="/usr/local/etc/"

PHP_UNIX_SOCKET_DIR_PATH="/var/run/php-fpm/"
PHP_UNIX_SOCKET_FILE_PATH="/var/run/php-fpm/www.sock"

PHP_UNIT_FILE="/etc/systemd/system/php-fpm-7.service"

yum update -y
yum install libxml2-devel pcre-devel openssl-devel gcc curl -y

PHP5_LATEST_STABLE = True

cd /tmp/src && tar -xvzf /tmp/src/php-7.4.22.tar.gz

cd php-7.4.22

########## Configure nginx openresty v 1.19.3.2 with lua jit, ssl, realip, http2 and sub nginx modules ##########
./configure \
--enable-fpm \
--with-mysqli

##### binaries are installed in /usr/local/bin/php & /usr/local/sbin/php-fpm
########## Compile nginx openresty from source ##########
#make && make install
make && make install

mkdir -p ${PID_FILE_DIR}
chown root:root ${PID_FILE_DIR}
pidFile="${PID_FILE_DIR}php-7.4.pid"
touch ${pidFile}

#/usr/local/etc/php-fpm.conf
mkdir -p ${PHP_CONFIG_DIR}
mv -f /tmp/php-fpm.conf /usr/local/etc/php-fpm.conf

mkdir -p ${PHP_UNIX_SOCKET_DIR_PATH}
chown ec2-user:root ${PHP_UNIX_SOCKET_DIR_PATH}
chmod +x ${PHP_UNIX_SOCKET_DIR_PATH}
chmod 755 -R ${PHP_UNIX_SOCKET_DIR_PATH}

########## Configure php unit systemd file ##########

if [ -f "$FILE" ]; then
mv -f $FILE $PHP_UNIT_FILE
FILE=$PHP_UNIT_FILE
chown root:root /etc/systemd/system/php-fpm-7.service
fi

if [ -f "$FILE" ]; then
systemctl daemon-reload
systemctl enable php-fpm-7.service
systemctl start php-fpm-7.service
systemctl status php-fpm-7.service
fi
########## Configure php unit systemd file ##########

#mkdir -p /opt/php-7.4/lib/php.ini

#touch /var/run/php-fpm/www.sock