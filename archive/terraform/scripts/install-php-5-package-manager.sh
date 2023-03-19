#!/bin/bash

set -x

mv /tmp/index.php /usr/local/openresty/nginx/html/index.php

# Set variables
SCRIPTS_DEST_DIR="/opt/kickstart/scripts/"

########## Check the Amazon linux packages ##########
which amazon-linux-extras

########## Install PHP 5.4 ##########
echo "Updating Amazon linux extra packacges..."

yum remove php-* -y 

# It still ask is this OK [y/d/N] which is not good for automation
yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm –y
yum install https://centos7.iuscommunity.org/ius-release.rpm –y

yum install php56u php56u-opcache php56u-xml php56u-mcrypt \
php56u-gd php56u-devel php56u-mysql php56u-intl php56u-mbstring \
php56u-bcmath php56u-soap -y 

# Check default PHP version
php --version

# Current PHP version
php -v