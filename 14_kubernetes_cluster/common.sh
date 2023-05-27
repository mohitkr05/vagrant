# https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
#!/bin/bash
set -euxo pipefail

cat >> /etc/ufw/sysctl.conf <<EOF
net/bridge/bridge-nf-call-ip6tables = 1
net/bridge/bridge-nf-call-iptables = 1
net/bridge/bridge-nf-call-arptables = 1
EOF

# disable swap
swapoff -a
sed -i '/swap/d' /etc/fstab

# Install docker kubeadm, kubectl and kubelet
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install ebtables ethtool
apt-get install -y docker.io apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl
