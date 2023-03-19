#!/bin/bash

source /opt/scripts/instance-source-info.sh

CONFIG_DIR=/opt/config/
mkdir -p ${CONFIG_DIR}
chown ec2-user:root -R ${CONFIG_DIR}
chmod 777 -R ${CONFIG_DIR}

echo ${PRIVATE_IP} > ${CONFIG_DIR}private.ip
echo ${PUBLIC_IP} > ${CONFIG_DIR}public.ip

