#!/bin/bash

PRIVATE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
PUBLIC_IP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
PUBLIC_HOSTNAME=$(curl http://169.254.169.254/latest/meta-data/public-hostname)

FILE=/opt/config/redis_endpoint.ip

if [ -f ${FILE} ]; then
    REDIS_ENDPOINT=`cat ${FILE}`
else
    REDIS_ENDPOINT=${PRIVATE_IP}
fi

echo ${PRIVATE_IP}
echo ${PUBLIC_IP}
echo ${PUBLIC_HOSTNAME}
echo ${REDIS_ENDPOINT}

export PRIVATE_IP=${PRIVATE_IP}
export PUBLIC_IP=${PUBLIC_IP}
export PUBLIC_HOSTNAME=${PUBLIC_HOSTNAME}
export REDIS_ENDPOINT=${REDIS_ENDPOINT}