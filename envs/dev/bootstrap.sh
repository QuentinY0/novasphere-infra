#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y nginx unzip curl awscli
systemctl enable nginx
systemctl start nginx

mkdir -p /etc/novasphere
SECRET=$(aws ssm get-parameter --name "/novasphere/dev/db_password" --with-decryption --region us-east-1 --query "Parameter.Value" --output text 2>/dev/null || echo "SecretInitDev2026!")
echo "DB_PASSWORD=$SECRET" > /etc/novasphere/app.conf
chmod 0640 /etc/novasphere/app.conf

echo "NovaSphere Dev - $(hostname)" > /var/www/html/index.html
