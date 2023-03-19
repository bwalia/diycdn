#!/bin/bash
if [ -z "$1" ]; then
REDIS_ENDPOINT=`cat /opt/config/redis_endpoint.ip`
else
REDIS_ENDPOINT="$1"
FILE=/opt/config/redis_endpoint.ip
echo $REDIS_ENDPOINT > ${FILE}
fi
echo "REDIS_ENDPOINT: ${REDIS_ENDPOINT}"
CONFIG_DIR=/opt/config/

SERVICE_NAME=openresty.service

UNIT_FILE=/etc/systemd/system/${SERVICE_NAME}
UNIT_FILE_TEMPLATE="/tmp/${SERVICE_NAME}.template"
UNIT_FILE_TEMPLATE_TMP="/tmp/${SERVICE_NAME}.temp"

if [ -f ${UNIT_FILE_TEMPLATE} ] && [ -f ${CONFIG_DIR}private.ip ]; then

    if [ -f ${UNIT_FILE_TEMPLATE_TMP} ]; then
        rm ${UNIT_FILE_TEMPLATE_TMP}
    fi

    cp ${UNIT_FILE_TEMPLATE} ${UNIT_FILE_TEMPLATE_TMP}

    if [ -f ${UNIT_FILE} ]; then
        mv ${UNIT_FILE} /tmp/${SERVICE_NAME}.old
    fi

    # REDIS_ENDPOINT=`cat /opt/config/redis_endpoint.ip`
    source /opt/scripts/instance-source-info.sh
    sed "s/\b\([0-9]\{1,3\}\.\)\{1,3\}[0-9]\{1,3\}\b/$REDIS_ENDPOINT/g" ${UNIT_FILE_TEMPLATE_TMP} > ${UNIT_FILE}

    systemctl daemon-reload
    systemctl enable ${SERVICE_NAME}
    systemctl restart ${SERVICE_NAME}

fi

SERVICE_NAME=services-manager.service

UNIT_FILE=/etc/systemd/system/${SERVICE_NAME}
UNIT_FILE_TEMPLATE="/tmp/${SERVICE_NAME}.template"
UNIT_FILE_TEMPLATE_TMP="/tmp/${SERVICE_NAME}.temp"

if [ -f ${UNIT_FILE_TEMPLATE} ] && [ -f ${CONFIG_DIR}private.ip ]; then

    if [ -f ${UNIT_FILE_TEMPLATE_TMP} ]; then
        rm ${UNIT_FILE_TEMPLATE_TMP}
    fi

    cp ${UNIT_FILE_TEMPLATE} ${UNIT_FILE_TEMPLATE_TMP}

    if [ -f ${UNIT_FILE} ]; then
        mv ${UNIT_FILE} /tmp/${SERVICE_NAME}.old
    fi

    source /opt/scripts/instance-source-info.sh
    sed "s/\b\([0-9]\{1,3\}\.\)\{1,3\}[0-9]\{1,3\}\b/$REDIS_ENDPOINT/g" ${UNIT_FILE_TEMPLATE_TMP} > ${UNIT_FILE}

    systemctl daemon-reload
    systemctl enable ${SERVICE_NAME}
    systemctl restart ${SERVICE_NAME}

fi
