#!/bin/bash

set -x

########## Install services manager ##########
echo "Installing Go App - The custom services config manager..."

HOMEDIR="/home/ec2-user/"
mkdir -p $HOMEDIR

FILE="/tmp/src/"
mkdir -p $FILE

#Move tls certs to opsapi certs dir or else opsapi will not start or fail to start https
CERT_FILE="${FILE}api_ssl_cert.crt"
if [ -f "$CERT_FILE" ] && [ -d "$HOMEDIR" ]; then
    cat ${CERT_FILE} | base64 -d > ${HOMEDIR}localhost.crt
fi

CERT_FILE="${FILE}api_ssl_cert.key"
if [ -f "$CERT_FILE" ] && [ -d "$HOMEDIR" ]; then
    cat ${CERT_FILE} | base64 -d > ${HOMEDIR}localhost.key
fi

API_SIGN_KEY_FILE=${HOMEDIR}api_sign.key
CERT_FILE="${FILE}api_sign.key"
if [ -f "$CERT_FILE" ] && [ -d "$HOMEDIR" ]; then
    cat ${CERT_FILE} | base64 -d > ${API_SIGN_KEY_FILE}
fi

if [ -f "$API_SIGN_KEY_FILE" ] && [ -d "$HOMEDIR" ]; then
API_SIGN_KEY=$(cat ${API_SIGN_KEY_FILE})
    curl -fSL  https://edgeone-public.s3.eu-west-2.amazonaws.com/src/go-services-manager/services.tar.gz -o /tmp/src/services.tar.gz

cd /tmp && tar -xvzf /tmp/src/services.tar.gz -C /tmp/src
BIN_FILE="${HOMEDIR}services"
mv /tmp/src/services ${BIN_FILE}
mv /tmp/src/static $HOMEDIR

chown ec2-user:root ${BIN_FILE}
chmod +x ${BIN_FILE}
chmod 777 ${BIN_FILE}

OPSAPI_TMP_UNIT_FILE="/tmp/services-manager.service"
OPSAPI_UNIT_FILE_TEMPLATE="${HOMEDIR}services-manager.service.template"
UNIT_FILE=""

    if [ -f "$OPSAPI_TMP_UNIT_FILE" ]; then
    cp ${OPSAPI_TMP_UNIT_FILE} ${OPSAPI_UNIT_FILE_TEMPLATE}
    # replace the SIGN KEY placeholder with the actual key
    sed -i "s/__SIGN_KEY__/$API_SIGN_KEY/" ${OPSAPI_TMP_UNIT_FILE}
    UNIT_FILE="/etc/systemd/system/services-manager.service"
    mv ${OPSAPI_TMP_UNIT_FILE} ${UNIT_FILE}
    FILE=${UNIT_FILE}
    chown root:root ${UNIT_FILE}
    chmod 777 ${UNIT_FILE}
    fi

    if [ -f "${UNIT_FILE}" ]; then
    systemctl daemon-reload
    systemctl enable services-manager.service
    systemctl start services-manager.service
    systemctl status services-manager.service
    fi

#nohup /home/ec2-user/services &

echo "Testing http://localhost:3333/"
curl -IL http://localhost:3333/

echo "Testing https://localhost:10443/"
curl -IL https://localhost:10443/
fi