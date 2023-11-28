#!/bin/bash


sudo apt install -y nova-compute mariadb-server python3-pymysql python3-openstackclient python3-novaclients  rabbitmq-server memcached python3-memcache etcd
sudo rabbitmqctl add_user openstack 123456789
sudo rabbitmqctl set_permissions openstack ".*" ".*" ".*"

ETCD_NAME="controller"
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster-01"
ETCD_INITIAL_CLUSTER="controller=http://192.168.56.254:2380"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://192.168.56.254:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://192.168.56.254:2379"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="http://192.168.56.254:2379"


GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '123456789';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '123456789';


keystone-manage bootstrap --bootstrap-password 123456789 \
  --bootstrap-admin-url http://controller:5000/v3/ \
  --bootstrap-internal-url http://controller:5000/v3/ \
  --bootstrap-public-url http://controller:5000/v3/ \
  --bootstrap-region-id RegionOne



export OS_USERNAME=admin
export OS_PASSWORD=123456789
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3


CREATE USER 'keystone'@'%' IDENTIFIED BY '123456789';