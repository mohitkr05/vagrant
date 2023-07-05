#!/bin/bash
set -euxo pipefail



# disable swap
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab


# Disable the firewall
systemctl disable --now ufw >/dev/null 2>&1

sudo tee /etc/modules-load.d/containerd.conf > /dev/null <<EOF
overlay
br_netfilter
EOF

sudo tee /etc/sysctl.d/kubernetes.conf > /dev/null <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system >/dev/null 2>&1

# Install docker kubeadm, kubectl and kubelet
export DEBIAN_FRONTEND=noninteractive
wget -qO - https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor | sudo dd of=/usr/share/keyrings/docker-archive-keyring.gpg
echo 'deb [ arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg ] https://download.docker.com/linux/ubuntu jammy stable' | sudo tee /etc/apt/sources.list.d/docker.list
wget -qO - https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor | sudo dd of=/usr/share/keyrings/kubernetes-archive-keyring.gpg
echo 'deb [ arch=amd64 signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg ] http://apt.kubernetes.io/ kubernetes-xenial main' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get -y update
sudo apt-get install -y ebtables ethtool
sudo apt-get install -y apt-transport-https curl

## Install and update containerd.io
sudo apt install -y containerd.io
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
sudo apt install -y kubeadm=1.26.0-00 kubelet=1.26.0-00 kubectl=1.26.0-00

sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config

echo -e "kubeadmin\nkubeadmin" | passwd root >/dev/null 2>&1
echo "export TERM=xterm" >> /etc/bash.bashrc

sudo tee /etc/hosts > /dev/null <<EOF
192.168.56.100   master.kube.cluster   master
192.168.56.101   worker1.kube.cluster worker1
192.168.56.102   worker2.kube.cluster worker2
EOF