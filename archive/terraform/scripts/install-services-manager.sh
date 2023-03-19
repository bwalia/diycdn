#!/bin/bash

set -x

########## Install services manager ##########
echo "Installing Go App - The custom services config manager..."

mkdir -p /home/ec2-user/
API_SIGN_KEY=$(cat /home/ec2-user/api_sign.key)

FILE="/tmp/src/"
mkdir -p $FILE

curl -fSL  https://edgeone-public.s3.eu-west-2.amazonaws.com/src/go-services-manager/services.tar.gz -o /tmp/src/services.tar.gz

cd /tmp && tar -xvzf /tmp/src/services.tar.gz -C /tmp/src

mv /tmp/src/services /home/ec2-user/services

chown ec2-user:root /home/ec2-user/services
chmod +x /home/ec2-user/services
chmod 777 /home/ec2-user/services

FILE="/tmp/services-manager.service"

if [ -f "$FILE" ]; then
sed -i "s/__SIGN_KEY__/$API_SIGN_KEY/" /tmp/services-manager.service
mv /tmp/services-manager.service /etc/systemd/system/services-manager.service
FILE=/etc/systemd/system/services-manager.service
chown root:root /etc/systemd/services-manager.service
fi

if [ -f "$FILE" ]; then
systemctl daemon-reload
systemctl enable services-manager.service
systemctl start services-manager.service
systemctl status services-manager.service
fi
#nohup /home/ec2-user/services &

curl -IL http://localhost:3333/
