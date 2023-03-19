#!/bin/bash

set -x

# Set variables
INSTALL_OPSAPI_BOOL=true
INSTALL_OPENRESTY_BOOL=true
  INSTALL_VARNISH_BOOL=false
  INSTALL_REDIS_BOOL=false
  INSTALL_PHP_BOOL=false
  INSTALL_MARIADB_BOOL=false

SCRIPTS_SRC_DIR="/tmp/scripts/"
NGINX_SCRIPTS_DEST_DIR="/opt/scripts/"

########## Make sure all scripts uploaded by terraform have correct executing permissions  ##########
chown ec2-user:root -R /tmp/scripts/

chmod +x -R /tmp/scripts/
chmod 755 -R /tmp/scripts/

#Install helper bash scripts which would be used later on while adding tenants

mkdir -p ${NGINX_SCRIPTS_DEST_DIR}

mv -f ${SCRIPTS_SRC_DIR}install-*.sh ${NGINX_SCRIPTS_DEST_DIR}
mv -f ${SCRIPTS_SRC_DIR}instance-*.sh ${NGINX_SCRIPTS_DEST_DIR}

chown ec2-user:root ${NGINX_SCRIPTS_DEST_DIR}
chmod +x ${NGINX_SCRIPTS_DEST_DIR}*.sh

/bin/bash /opt/scripts/install-base.sh

########## BASE INSTALL MOVES ALL SCRIPTS TO DEDICATED DIR ##########

# Save IPs for later use
    /bin/bash /opt/scripts/instance-save-info.sh

if $INSTALL_REDIS_BOOL; then
  # Install Redis
  echo 'Installing Redis...'
  /bin/bash /opt/scripts/install-redis.sh
fi

if $INSTALL_OPSAPI_BOOL; then
  # Install services manager go app
  echo 'Installing OPSAPI...'
    /bin/bash /opt/scripts/install-services-manager.sh
fi

if $INSTALL_OPENRESTY_BOOL; then
  # Install nginx / openresty
  echo 'Installing OPSAPI...'
    /bin/bash /opt/scripts/install-openresty-from-src.sh
fi

if $INSTALL_PHP_BOOL; then
  # Install PHP 7.4 from source
  echo 'Installing PHP7...'
    /bin/bash /opt/scripts/install-php-7.sh
#Install PHP 5.4 from source
#/bin/bash /opt/scripts/install-php-5.sh
fi

if $INSTALL_VARNISH_BOOL; then
  # Install varnish
  echo 'Installing varnish...'
  /bin/bash /opt/scripts/install-varnish.sh
fi

if $INSTALL_MARIADB_BOOL; then
  # Install MariaDB
  echo 'Installing MariaDB...'
  /bin/bash /opt/scripts/install-mariadb.sh
fi