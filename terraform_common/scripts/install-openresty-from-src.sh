#!/bin/bash

set -x

#sudo usermod -a -G apache ec2-user

# Set variables
#OPENRESTY_VERSION="1.19.3.2"
OPENRESTY_VERSION="1.21.4.1"
# Pass OPENRESTY_VERSION_PROD github action variable to this script
# 2022 09 06

TENANTS_ROOT_DIR="/usr/local/openresty/nginx/"

TMP_UNIT_FILE="/tmp/openresty.service"
TMP_UNIT_FILE_TEMPLATE="/tmp/openresty.service.template"

TENANTS_CONFIG_DIR="/opt/nginx/conf/nginx-tenants.d/"

PID_FILE_DIR="/var/nginx/"
NGINX_BINARY="/usr/local/openresty/bin"
NGINX_UNIX_SOCKET_PATH="/var/run/nginx/"
NGINX_UNIX_SOCKET="/var/run/nginx/nginx.sock"

mkdir -p ${NGINX_UNIX_SOCKET_PATH}
chmod +x ${NGINX_UNIX_SOCKET_PATH}
chown ec2-user:root ${NGINX_UNIX_SOCKET_PATH}
chmod 755 -R ${NGINX_UNIX_SOCKET_PATH}

SCRIPTS_SRC_DIR="/tmp/scripts/"

SCRIPTS_DEST_DIR="/opt/kickstart/scripts/"
NGINX_SCRIPTS_DEST_DIR="/opt/nginx/scripts/"

NGINX_HTML_DIR="${TENANTS_ROOT_DIR}html/"
NGINX_LUA_DIR="${TENANTS_ROOT_DIR}lua/"
NGINX_CONF_DIR="${TENANTS_ROOT_DIR}conf/"

NGINX_TENANTS_DIR="/usr/share/nginx/html/tenants/"
########## Set paths
mkdir -p ${NGINX_SCRIPTS_DEST_DIR}
mkdir -p ${NGINX_LUA_DIR}

########## Move bash files used by nginx and services manager go app
mv -f ${SCRIPTS_SRC_DIR}nginx-*.sh ${NGINX_SCRIPTS_DEST_DIR}
chown ec2-user:root ${NGINX_SCRIPTS_DEST_DIR}
chmod +x ${NGINX_SCRIPTS_DEST_DIR}*.sh

########## Install nginx openresty ##########
echo "Installing Nginx Openresty-${OPENRESTY_VERSION}..."

########## Add nginx openresty repo ##########

yum-config-manager --add-repo https://openresty.org/package/amazon/openresty.repo
########## Add nginx openresty dependencies pcre-devel and openssl gcc and curl ##########
yum install pcre-devel openssl-devel gcc curl -y

########## Get nginx openresty v ${OPENRESTY_VERSION} src / tar ##########
wget -O /tmp/src/openresty-${OPENRESTY_VERSION}.tar.gz https://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz

yum groupinstall -y "Development Tools"
yum install -y httpd httpd-devel pcre pcre-devel libxml2 libxml2-devel curl curl-devel openssl openssl-devel
yum install -y httpd-devel pcre pcre-devel libxml2 libxml2-devel curl curl-devel openssl openssl-devel

cd /tmp/src && tar -xvzf /tmp/src/ModSecurity-nginx_refactoring.tar.gz

cd /tmp/src/ModSecurity-nginx_refactoring/ && sed -i '/AC_PROG_CC/a\AM_PROG_CC_C_O' configure.ac && sed -i '1 i\AUTOMAKE_OPTIONS = subdir-objects' Makefile.am && ./autogen.sh && ./configure --enable-standalone-module --disable-mlogc && make

cd /tmp/src && tar -xvzf /tmp/src/openresty-${OPENRESTY_VERSION}.tar.gz

cd openresty-${OPENRESTY_VERSION}

########## Configure nginx openresty v ${OPENRESTY_VERSION} with lua jit, ssl, realip, http2 and sub nginx modules ##########
./configure \
   --with-pcre-jit \
   --with-http_ssl_module \
   --with-http_realip_module \
   --with-http_stub_status_module \
   --with-http_sub_module \
   --with-http_v2_module \
   --add-module=/tmp/src/ModSecurity-nginx_refactoring/nginx/modsecurity
# --add-module=../lua-nginx-module \
# --add-module=../ngx_devel_kit
#If WAF compile these too
# ./configure \
# --add-module=../lua-nginx-module
# --add-module=../ngx_devel_kit

########## Compile nginx openresty from source ##########
#make && make install
gmake && gmake install

export PATH="$PATH:/usr/local/openresty/bin"

mkdir -p ${NGINX_CONF_DIR}

cp /tmp/src/ModSecurity-nginx_refactoring/modsecurity.conf-recommended ${TENANTS_ROOT_DIR}conf/modsecurity.conf
cp /tmp/src/ModSecurity-nginx_refactoring/unicode.mapping ${TENANTS_ROOT_DIR}conf/unicode.mapping
sed -i "s/SecRuleEngine DetectionOnly/SecRuleEngine On/" ${TENANTS_ROOT_DIR}conf/modsecurity.conf

#git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git

cd /tmp/src && tar -xvzf /tmp/src/owasp-modsecurity-crs-3.3-dev.tar.gz

mkdir -p ${TENANTS_ROOT_DIR}conf/owasp-modsecurity-crs/rules/

########## Copy default nginx core config and default edgeone.co.uk default website ##########
mv -f /tmp/nginx/nginx-core.d/ ${TENANTS_ROOT_DIR}conf/nginx-core.d/
# set internal sites and systems api nginx config dedicated location
mv -f /tmp/nginx/nginx-ssl.d/ ${TENANTS_ROOT_DIR}conf/nginx-ssl.d/
mv -f /tmp/nginx/nginx-opsapi.d/ ${TENANTS_ROOT_DIR}conf/nginx-opsapi.d/
mv -f /tmp/nginx/nginx-tenants.d/ ${TENANTS_ROOT_DIR}conf/nginx-tenants.d/
mv -f /tmp/nginx/ssl/* /etc/ssl/

#mv -f /tmp/nginx/html/edgeone-default-tenant/ ${NGINX_HTML_DIR}edgeone-default-tenant/

mv -f /tmp/nginx/lua/* ${TENANTS_ROOT_DIR}lua/
#mv -f /tmp/nginx/conf/* ${TENANTS_ROOT_DIR}conf/

mv -f /tmp/nginx.conf ${TENANTS_ROOT_DIR}conf/nginx.conf

mv /tmp/src/ModSecurity-nginx_refactoring/crs-setup.conf.example ${TENANTS_ROOT_DIR}conf/owasp-modsecurity-crs/crs-setup.conf
mv /tmp/src/ModSecurity-nginx_refactoring/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example ${TENANTS_ROOT_DIR}conf/owasp-modsecurity-crs/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf
mv /tmp/src/ModSecurity-nginx_refactoring/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example ${TENANTS_ROOT_DIR}conf/owasp-modsecurity-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf

cat <<EOF >> ${TENANTS_ROOT_DIR}conf/modsec_includes.conf
include modsecurity.conf
include owasp-modsecurity-crs/crs-setup.conf
include owasp-modsecurity-crs/rules/*.conf
EOF

yum install openresty-resty -y

mkdir -p /home/ec2-user/src/

mv /tmp/src/luarocks-3.7.0.tar.gz /home/ec2-user/src/luarocks-3.7.0.tar.gz

cd /home/ec2-user/src/ && tar -xvzf /home/ec2-user/src/luarocks-3.7.0.tar.gz
cd luarocks-3.7.0
./configure --prefix=/usr/local/openresty/luajit \
    --with-lua=/usr/local/openresty/luajit/ \
    --lua-suffix=jit \
    --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1
make
make install

cd /home/ec2-user/src/
/usr/local/openresty/luajit/bin/luarocks install lua-resty-auto-ssl
mkdir -p /etc/resty-auto-ssl
chown -R root:ec2-user /etc/resty-auto-ssl/
chmod -R 775 /etc/resty-auto-ssl

openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
  -subj '/CN=sni-support-required-for-valid-ssl' \
  -keyout /etc/ssl/resty-auto-ssl-fallback.key \
  -out /etc/ssl/resty-auto-ssl-fallback.crt

#${TENANTS_ROOT_DIR}sbin/nginx -V

########## Configure nginx openresty unit systemd file ##########

UNIT_FILE=""

if [ -f "$TMP_UNIT_FILE" ]; then
UNIT_FILE="/etc/systemd/system/openresty.service"
#Template is used later on by Go services
cp ${TMP_UNIT_FILE} ${TMP_UNIT_FILE_TEMPLATE}
mv ${TMP_UNIT_FILE} ${UNIT_FILE}
FILE=${UNIT_FILE}
chown root:root ${UNIT_FILE}
chmod 777 ${UNIT_FILE}
fi

if [ -f "$UNIT_FILE" ]; then
systemctl daemon-reload
systemctl enable openresty.service
/usr/local/openresty/bin/openresty -t && systemctl start openresty.service
systemctl status openresty.service
fi
########## Configure nginx openresty unit systemd file ##########


mkdir -p ${NGINX_TENANTS_DIR}
chown ec2-user:root -R ${NGINX_TENANTS_DIR}
chmod 755 -R ${NGINX_TENANTS_DIR}

########## Copy default nginx tenant OPS API ##########
#mv /tmp/nginx/edgeone-api.d/ ${TENANTS_ROOT_DIR}conf/edgeone-api.d/

#  nginx pid file location preset
mkdir -p ${PID_FILE_DIR}
chown root:root ${PID_FILE_DIR}
pidFile="${PID_FILE_DIR}nginx.pid"
touch ${pidFile}

logFileDir="/var/log/nginx/"

# nginx logs location preset
mkdir -p ${logFileDir}

#mv /tmp/openresty.service /lib/systemd/system/openresty.service

########## Add nginx/openresty in the path ##########
export PATH=/usr/local/openresty/bin:$PATH
echo 'export PATH=/usr/local/openresty/bin:$PATH' >> ~/.bashrc
#Also add path for sudo commands in root bashrc
echo 'export PATH=/usr/local/openresty/bin:$PATH' >> /root/.bashrc

########## Check and display openresty version in console ##########
openresty -V

########## Restart openresty service so default config and apis are available ##########

# Set paths for nginx config for tenants
mkdir -p ${TENANTS_CONFIG_DIR}
# set tenants nginx config dedicated location so nginx tenant specific configs can be added via API
chown ec2-user:root -R ${TENANTS_ROOT_DIR}
chown ec2-user:root -R ${TENANTS_CONFIG_DIR}

#cron jobs here
#Set nginx auto reload bash file for the crontab

#Load the crontab with above bash script so it can run every min
# cfgCronBashFile="nginx-update-set-cronjob.sh"
# mv -f ${SCRIPTS_SRC_DIR}${cfgCronBashFile} ${NGINX_SCRIPTS_DEST_DIR}${cfgCronBashFile}
# /bin/bash ${NGINX_SCRIPTS_DEST_DIR}${cfgCronBashFile}

#Create a secure Diffie-Hellman passphrase
openssl dhparam -out /usr/local/openresty/dhparam.pem 2048

systemctl restart crond.service

/bin/bash ${NGINX_SCRIPTS_DEST_DIR}nginx-configtest.sh
/bin/bash ${NGINX_SCRIPTS_DEST_DIR}nginx-openresty-prepare.sh

/bin/bash ${NGINX_SCRIPTS_DEST_DIR}nginx-reload.sh

mkdir -p /usr/local/openresty/luajit/bin/resty-auto-ssl/
chown ec2-user:root -R /usr/local/openresty/luajit/bin/resty-auto-ssl/
chmod 777 -R /usr/local/openresty/luajit/bin/resty-auto-ssl/

/usr/local/openresty/luajit/bin/resty-auto-ssl/dehydrated --register --accept-terms

mkdir -p /tmp/letsencrypt/
chmod 777 -R /tmp/letsencrypt/
touch /tmp/letsencrypt/config

mkdir -p /var/www/dehydrated
chmod 777 -R /var/www/dehydrated

NGINX_SSL_DIR="/opt/nginx/ssl/"

mkdir -p ${NGINX_SSL_DIR}
chown ec2-user:root -R ${NGINX_SSL_DIR}

#Move tls certs to nginx certs dir or else nginx will not start or fail to start https
CERT_FILE="/tmp/src/api_ssl_cert.crt"

if [ -f "$CERT_FILE" ]; then
cat ${CERT_FILE} | base64 -d > ${NGINX_SSL_DIR}api_ssl_cert.crt
fi

CERT_FILE="/tmp/src/api_ssl_cert.key"

if [ -f "$CERT_FILE" ]; then
cat ${CERT_FILE} | base64 -d > ${NGINX_SSL_DIR}api_ssl_cert.key
fi