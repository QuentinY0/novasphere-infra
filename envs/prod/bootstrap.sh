#!/bin/bash
apt-get update -y
apt-get install -y nginx
systemctl enable nginx
systemctl start nginx
echo "NovaSphere - $(hostname)" > /var/www/html/index.html
