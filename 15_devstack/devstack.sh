#!/bin/bash
sudo apt update -y && apt upgrade -y
sudo apt install -y git vim-gtk libxml2-dev libxslt1-dev libpq-dev python-pip libsqlite3-dev
echo "vagrant ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/stack
git clone https://git.openstack.org/openstack-dev/devstack
sudo chown -R vagrant:vagrant /home/vagrant/devstack
cd devstack
cat > "local.conf" <<EOF
[[local|localrc]]

DEST=/opt/stack
LOGFILE=/opt/stack/logs/stack.sh.log
SCREEN_LOGDIR=/opt/stack/logs/screen

ADMIN_PASSWORD=admin
DATABASE_PASSWORD=123456789
RABBIT_PASSWORD=123456789
SERVICE_PASSWORD=123456789
SERVICE_TOKEN=123456789

HOST_IP=192.168.56.254
EOF

bash stack.sh 