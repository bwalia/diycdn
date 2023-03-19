#!/bin/bash

# Install mariadb locally for dev/testing
echo "Installing and configiring mariadb..."
 
# Install amazon-linux-extras mariadb package
sudo amazon-linux-extras | grep mariadb

sudo tee /etc/yum.repos.d/mariadb.repo<<EOF
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.5/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

sudo yum makecache
sudo yum repolist
sudo yum install MariaDB-server MariaDB-client -y

sudo systemctl enable --now mariadb
sudo systemctl start mariadb

root_password=password

echo -e "\ny\ny\n${root_password}\n${root_password}\ny\ny\ny\ny" | sudo mysql_secure_installation

# Did it work?
mysql -u root -p${root_password} -e "SELECT 1+1";

# Make sure that NOBODY can access the server without a password
sudo mysql -e "UPDATE mysql.user SET Password = PASSWORD('$root_password') WHERE User = 'root'"
 
# Kill the anonymous users
sudo mysql -e "DROP USER IF EXISTS ''@'localhost'"
# Because our hostname varies we'll use some Bash magic here.
sudo mysql -e "DROP USER IF EXISTS ''@'$(hostname)'"
# Kill off the demo database
sudo mysql -e "DROP DATABASE IF EXISTS test"

echo "Creating staging database..."
 
sudo mysql -e "CREATE DATABASE IF NOT EXISTS staging"
 
echo "Creating production database..."
 
sudo mysql -e "CREATE DATABASE IF NOT EXISTS production"
 
echo "Creating table tasks in staging database..."
 
sudo mysql -e "use staging;CREATE TABLE IF NOT EXISTS tasks ( \
    task_id INT AUTO_INCREMENT PRIMARY KEY, \
    title VARCHAR(255) NOT NULL, \
    start_date DATE, \
    due_date DATE, \
    status TINYINT NOT NULL, \
    priority TINYINT NOT NULL, \
    description TEXT \
    ) ENGINE=INNODB;" \
 
echo "Table tasks created."
 
echo "Inserting data into tasks table..."
 
query1="use staging; INSERT INTO tasks (title, start_date, due_date, status, priority, description) \
        VALUES('task1', '2020-07-01', '2020-07-31', 1, 1, 'this is the first task')"
 
 
query2="use staging; INSERT INTO tasks (title, start_date, due_date, status, priority, description) \
        VALUES('task2', '2020-08-01', '2020-08-31', 2, 2, 'this is the second task')"
 
 
query3="use staging; INSERT INTO tasks (title, start_date, due_date, status, priority, description) \
        VALUES('task3', '2020-09-01', '2020-09-30', 1, 1, 'this is the third task')"
 
 
query4="use staging; INSERT INTO tasks (title, start_date, due_date, status, priority, description) \
        VALUES('task4', '2020-10-01', '2020-10-31', 1, 1, 'this is fourth task')"
 
sudo mysql -e "$query1"
sudo mysql -e "$query2"
sudo mysql -e "$query3"
sudo mysql -e "$query4"
 
echo "Inserting dummy data into tasks table finished"
 
echo "Creating table named 'completed' into production database..."
 
sudo mysql -e "use production; CREATE TABLE IF NOT EXISTS completed ( \
    task_id INT AUTO_INCREMENT PRIMARY KEY, \
    task_name VARCHAR(255) NOT NULL, \
    finished_date DATE, \
    status TEXT, \
    description TEXT \
    ) ENGINE=INNODB;" \
 
echo "Populating completed table with some dummy data..."
 
query_1="use production; INSERT INTO completed (task_name, finished_date, status, description) \
        VALUES('task1', '2020-07-31','done', 'task one finished')"
 
query_2="use production; INSERT INTO completed (task_name, finished_date, status, description) \
        VALUES('task2', '2020-08-31','completed', 'task two finished')"
 
query_3="use production; INSERT INTO completed (task_name, finished_date, status, description) \
        VALUES('task3', '2020-09-30','done', 'task three finished')"
 
query_4="use production; INSERT INTO completed (task_name, finished_date, status, description) \
        VALUES('task4', '2020-10-31','done', 'task four finished')"
 
sudo mysql -e "$query_1"
sudo mysql -e "$query_2"
sudo mysql -e "$query_3"
sudo mysql -e "$query_4"
 
echo "Database named 'completed' pupulated with dummy data."
 
echo "Creating staging_user and grant all permissions to staging database..."
 
mysql -e "CREATE USER IF NOT EXISTS 'staging_user'@'localhost' IDENTIFIED BY 'password1'"
 
mysql -e "GRANT ALL PRIVILEGES ON staging.* to 'staging_user'@'localhost'"
 
echo "Creating production_user and grant all permissions to production database..."
 
mysql -e "CREATE USER IF NOT EXISTS 'production_user'@'localhost' IDENTIFIED BY 'password2'"
 
mysql -e "GRANT ALL PRIVILEGES ON production.* to 'production_user'@'localhost'"
 
# Make our changes take effect
sudo mysql -e "FLUSH PRIVILEGES"