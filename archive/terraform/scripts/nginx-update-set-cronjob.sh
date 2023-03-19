# !/bin/bash
echo '* * * * * /bin/bash /opt/nginx/scripts/nginx-update-tenant.sh' > /tmp/nginx-update-set-cronjob.txt
sudo -u root /bin/bash -c 'crontab /tmp/nginx-update-set-cronjob.txt'
