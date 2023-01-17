#! /bin/bash
# echo "Do nothing"

echo "Performing yum update and installing epel-release"
yum -y update && yum -y install epel-release 

echo "Installing NGINX"
yum -y install nginx

echo "Enabling NGINX"
systemctl enable nginx

echo "Starting NGINX"
systemctl start nginx

echo "I have configured NGINX"