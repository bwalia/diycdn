#!/bin/bash

set -x

########## Check the OS release ##########
cat /etc/os-release

########## Install nginx openresty ##########
echo "Updating yum packacges..."

########## Yum base packages update ##########

yum update -y

yum install pcre-devel openssl-devel gcc curl -y

chown ec2-user:root -R /tmp/scripts/

chmod +x -R /tmp/scripts/
chmod 755 -R /tmp/scripts/

#Setup swap, size of swapfile in megabytes
dd if=/dev/zero of=/swapfile bs=1M count=1024

mkswap /swapfile
chmod 0600 /swapfile
swapon /swapfile

echo "/swapfile swap swap defaults 0 0" >> /etc/fstab

echo '--------------------------------------------'
echo 'Check whether the swap space created or not?'
echo '--------------------------------------------'

swapon --show

