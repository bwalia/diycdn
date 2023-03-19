#!/bin/bash

set -x

# Set variables
SCRIPTS_SRC_DIR="/tmp/scripts/"
SCRIPTS_DEST_DIR="/opt/scripts/"


########## Make sure all scripts uploaded by terraform have correct executing permissions  ##########
chown ec2-user:root -R /tmp/scripts/

chmod +x -R /tmp/scripts/
chmod 755 -R /tmp/scripts/

#Install helper bash scripts which would be used later on while adding tenants

mkdir -p ${SCRIPTS_DEST_DIR}

mv -f ${SCRIPTS_SRC_DIR}install-*.sh ${SCRIPTS_DEST_DIR}
chown ec2-user:root ${SCRIPTS_DEST_DIR}
chmod +x ${SCRIPTS_DEST_DIR}*.sh

/bin/bash /opt/scripts/install-base.sh

########## BASE INSTALL MOVES ALL SCRIPTS TO DEDICATED DIR ##########

#Install Redis
/bin/bash /opt/scripts/install-redis.sh

#Install services manager go app
/bin/bash /opt/scripts/install-services-manager.sh

#Install nginx / openresty
/bin/bash /opt/scripts/install-nginx.sh

#Install PHP 7.4 from source
#/bin/bash /opt/scripts/install-php-7.sh

#Install PHP 5.4 from source
#/bin/bash /opt/scripts/install-php-5.sh

#Install varnish
#/bin/bash /opt/scripts/install-varnish.sh

#Install MariaDB
#/bin/bash /opt/scripts/install-mariadb.sh
