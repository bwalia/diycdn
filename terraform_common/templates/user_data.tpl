#!/bin/bash

mkdir -p ~centos/.ssh
cat > ~centos/.ssh/authorized_keys << EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCZXVX5mqlI2eqZYJMwyoTxYKbKrkBYi1wHKrQiAmqN/yU+CLN3/Nl1ilBylOpsk/awh9eHoyPypOCSfC5xUFHjcF1VuzrlPZyU8Pwirhb5wzq+PfSfjKORokjhTaJkzGauAHCGQe+VkvWkprZJ7JoTJ9B0TB4ftiHXOWMbAnX0kv9fqkIC7jGJ8gvOBTcHJDmknCd7c4a2YIO3M2yCIgdu26zsQ6IxdQOAmhhhHPabunwa2onyr1ZuTjQ2oRc3iP6s+wsWwOsHOoDfHgvHXLJiq5YMobtp0BvBFT87WBkILNG5zGYCMBNVMOUF2t26Ta3Ov1SrYJvJLuJ6fizGRYXp balinderwalia@localhost
EOF

chown -R centos:centos ~centos/.ssh
chmod 700 ~centos/.ssh
chmod 400 ~centos/.ssh/authorized_keys

sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
sudo yum install -y jq zip unzip

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install -b /usr/local/sbin

sudo amazon-linux-extras install docker
sudo service docker start

sudo systemctl status amazon-ssm-agent
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent

cd /opt && \
  curl http://aws-cloudwatch.s3.amazonaws.com/downloads/CloudWatchMonitoringScripts-1.2.1.zip -O  && \
  unzip CloudWatchMonitoringScripts-1.2.1.zip && \
  rm -f CloudWatchMonitoringScripts-1.2.1.zip && \
  echo "*/5 * * * * /opt/aws-scripts-mon/mon-put-instance-data.pl --mem-used-incl-cache-buff --mem-util --disk-space-util --disk-path=/ --from-cron" | crontab -


