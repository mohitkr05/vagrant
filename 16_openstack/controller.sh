#!/bin/bash

## I have deliberately made it redundant so that you can update the passwords as per your requirements\

PASSWORD="123456789"
# ADMIN_PASS - Password of user admin
ADMIN_PASS=$PASSWORD
# CINDER_DBPASS - Database password for the Block Storage service
CINDER_DBPASS=$PASSWORD
# CINDER_PASS - Password of Block Storage service user cinder
CINDER_PASS=$PASSWORD
# DASH_DBPASS - Database password for the Dashboard
DASH_DBPASS=$PASSWORD
# DEMO_PASS - Password of user demo
DEMO_PASS=$PASSWORD
# GLANCE_DBPASS - Database password for Image service
GLANCE_DBPASS=$PASSWORD
# GLANCE_PASS - Password of Image service user glance
GLANCE_PASS=$PASSWORD
# KEYSTONE_DBPASS - Database password of Identity service
KEYSTONE_DBPASS=$PASSWORD
# METADATA_SECRET - Secret for the metadata proxy
METADATA_SECRET=$PASSWORD
# NEUTRON_DBPASS - Database password for the Networking service
NEUTRON_DBPASS=$PASSWORD
# NEUTRON_PASS - Password of Networking service user neutron
NEUTRON_PASS=$PASSWORD
# NOVA_DBPASS - Database password for Compute service
NOVA_DBPASS=$PASSWORD
# NOVA_PASS - Password of Compute service user nova
NOVA_PASS=$PASSWORD
# PLACEMENT_PASS - Password of the Placement service user placement
PLACEMENT_PASS=$PASSWORD
# RABBIT_PASS -  Password of RabbitMQ user openstack
RABBIT_PASS=$PASSWORD

# Update and upgrade the system
sudo apt update -y
sudo apt upgrade -y

# Install necessary packages
sudo apt install -y crudini python3-dev python3-pip nova-compute mariadb-server python3-pymysql python3-openstackclient python3-novaclient rabbitmq-server memcached python3-memcache etcd openstack-dashboard

# Install and configure rabbitmq 

sudo rabbitmqctl add_user openstack $RABBIT_PASS
sudo rabbitmqctl set_permissions openstack ".*" ".*" ".*"

# Install and configure MariaDB for Keystone
sudo systemctl enable mariadb
sudo systemctl start mariadb

# Secure MariaDB installation
sudo mysql_secure_installation

# Create databases and users for Keystone

sudo mysql -e "CREATE DATABASE keystone;"
sudo mysql -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY `$KEYSTONE_DB_PASS`;"
sudo mysql -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY `$KEYSTONE_DB_PASS`;"


# Configure ETCD 
echo "export OS_USERNAME=admin" >> admin-openrc.sh
echo "export OS_PASSWORD=$ADMIN_PASS" >> admin-openrc.sh
echo "export OS_PROJECT_NAME=admin" >> admin-openrc.sh
echo "export OS_USER_DOMAIN_NAME=Default" >> admin-openrc.sh
echo "export OS_PROJECT_DOMAIN_NAME=Default" >> admin-openrc.sh
echo "export OS_AUTH_URL=http://controller:5000/v3" >> admin-openrc.sh
echo "export OS_IDENTITY_API_VERSION=3" >> admin-openrc.sh


echo "export ETCD_NAME=controller"  >> etcd-openrc.sh
echo "export ETCD_DATA_DIR='/var/lib/etcd'" >> etcd-openrc.sh
echo "export ETCD_INITIAL_CLUSTER_STATE='new'" >> etcd-openrc.sh
echo "export ETCD_INITIAL_CLUSTER_TOKEN='etcd-cluster-01'" >> etcd-openrc.sh
echo "export ETCD_INITIAL_CLUSTER='controller'='http://192.168.56.254:2380'" >> etcd-openrc.sh
echo "export ETCD_INITIAL_ADVERTISE_PEER_URLS='http://192.168.56.254:2380'" >> etcd-openrc.sh
echo "export ETCD_ADVERTISE_CLIENT_URLS='http://192.168.56.254:2379'" >> etcd-openrc.sh
echo "export ETCD_LISTEN_PEER_URLS='http://0.0.0.0:2380'" >> etcd-openrc.sh
echo "export ETCD_LISTEN_CLIENT_URLS='http://192.168.56.254:2379'" >> etcd-openrc.sh


# Install Keystone
sudo apt install -y keystone

# Configure Keystone

sudo cp /etc/keystone/keystone.conf /etc/keystone/keystone.conf.orig
sudo crudini --set /etc/keystone/keystone.conf database connection "mysql+pymysql://keystone:$KEYSTONE_DB_PASS@localhost/keystone"


# Populate the Keystone database
sudo su -s /bin/sh -c "keystone-manage db_sync" keystone

# Initialize Fernet key repositories
sudo keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
sudo keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

# Bootstrap Keystone
sudo keystone-manage bootstrap --bootstrap-password $ADMIN_PASS \
  --bootstrap-admin-url http://controller:5000/v3/ \
  --bootstrap-internal-url http://controller:5000/v3/ \
  --bootstrap-public-url http://controller:5000/v3/ \
  --bootstrap-region-id RegionOne

# Configure Apache for Keystone
sudo cp /etc/apache2/sites-available/keystone.conf /etc/apache2/sites-available/keystone.conf.orig
sudo crudini --set /etc/apache2/sites-available/keystone.conf keystone_authtoken www_authenticate_uri http://controller:5000
sudo crudini --set /etc/apache2/sites-available/keystone.conf keystone_authtoken auth_url http://controller:5000
sudo crudini --set /etc/apache2/sites-available/keystone.conf keystone_authtoken memcached_servers "controller:11211"

# Enable the Apache keystone virtual host
sudo a2ensite keystone

# Restart Apache
sudo systemctl restart apache2

# Source the admin credentials
echo "export OS_USERNAME=admin" >> admin-openrc.sh
echo "export OS_PASSWORD=$ADMIN_PASS" >> admin-openrc.sh
echo "export OS_PROJECT_NAME=admin" >> admin-openrc.sh
echo "export OS_USER_DOMAIN_NAME=Default" >> admin-openrc.sh
echo "export OS_PROJECT_DOMAIN_NAME=Default" >> admin-openrc.sh
echo "export OS_AUTH_URL=http://controller:5000/v3" >> admin-openrc.sh
echo "export OS_IDENTITY_API_VERSION=3" >> admin-openrc.sh

# Configure Glance 

GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY `$GLANCE_DBPASS`;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY `$GLANCE_DBPASS`;


# Verify Keystone installation
openstack project list

echo "OpenStack controller installation complete."
