#!/bin/bash

set -x
#SSH_USER="ec2-user"

#!/bin/bash
###############################################
# To use: 
# chmod +x install-redis.sh
# ./install-redis.sh
###############################################
version=3.2.0

echo "*****************************************"
echo " 1. Prerequisites: Install updates, set time zones, install GCC and make"
echo "*****************************************"
#yum -y update
#ln -sf /usr/share/zoneinfo/America/Los_Angeles \/etc/localtime
#yum -y install gcc gcc-c++ make 
echo "*****************************************"
echo " 2. Download, Untar and Make Redis $version"
echo "*****************************************"
cd /usr/local/src
wget "http://download.redis.io/releases/redis-$version.tar.gz"
tar xzf redis-$version.tar.gz
rm redis-$version.tar.gz -f
cd redis-$version
make distclean
make
echo "*****************************************"
echo " 3. Create Directories and Copy Redis Files"
echo "*****************************************"
mkdir /etc/redis /var/lib/redis
cp src/redis-server src/redis-cli /usr/local/bin
echo "*****************************************"
echo " 4. Configure Redis.Conf"
echo "*****************************************"
echo " Edit redis.conf as follows:"
echo " 1: ... daemonize yes"
echo " 2: ... bind 127.0.0.1"
echo " 3: ... dir /var/lib/redis"
echo " 4: ... loglevel notice"
echo " 5: ... logfile /var/log/redis.log"
echo "*****************************************"
sed -e "s/^daemonize no$/daemonize yes/" -e "s/^# bind 127.0.0.1$/bind 127.0.0.1 ::1/" -e "s/^dir \.\//dir \/var\/lib\/redis\//" -e "s/^loglevel verbose$/loglevel notice/" -e "s/^logfile stdout$/logfile \/var\/log\/redis.log/" redis.conf | tee /etc/redis/redis.conf
echo "*****************************************"
echo " 5. Download init Script"
echo "*****************************************"
wget https://raw.github.com/saxenap/install-redis-amazon-linux-centos/master/redis-server
echo "*****************************************"
echo " 6. Move and Configure Redis-Server"
echo "*****************************************"
mv redis-server /etc/init.d
chmod 755 /etc/init.d/redis-server
echo "*****************************************"
echo " 7. Auto-Enable Redis-Server"
echo "*****************************************"
chkconfig --add redis-server
chkconfig --level 345 redis-server on
echo "*****************************************"
echo " 8. Start Redis Server"
echo "*****************************************"
#service redis-server start
echo "*****************************************"
echo " Complete!"
echo " You can test your redis installation using the redis console:"
echo "   $ /usr/local/redis-$version/src/redis-cli"
echo "   redis> set foo bar"
echo "   OK"
echo "   redis> get foo"
echo "   bar"
echo "*****************************************"
#read -p "Press [Enter] to continue..."

FILE="/tmp/redis.conf"
if [ -f "$FILE" ]; then
mv $FILE /etc/redis/redis.conf
fi

#service redis-server stop
service redis-server start










































