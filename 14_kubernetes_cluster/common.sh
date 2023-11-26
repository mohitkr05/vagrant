#!/bin/bash


# 1. Hostnames

sudo tee /etc/hosts > /dev/null <<EOF
192.168.56.101   master.example.com   master
192.168.56.111   worker1.example.com worker1
192.168.56.112   worker2.example.com worker2
EOF

# 2. Disable the swap

sudo swapoff -a
sudo sed -i '/ swap/d' /etc/fstab

# 3. Load the kernel modules

sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# 4. Set the kernel parameters

sudo tee /etc/sysctl.d/99-kubernetes-cri.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF


sudo sysctl --system

# 5. Installing containerd and Docker

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl ebtables gnupg lsb-release

sudo mkdir -p /etc/apt/keyrings

sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg >/dev/null 2>&1
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt -y update 
sudo apt-get install -y containerd docker.io


sudo tee  /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker vagrant

sudo curl -L "https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname
-s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo chown vagrant /var/run/docker.sock

sudo docker-compose --version
sudo docker --version


sudo mkdir -p /etc/containerd/
sudo chown vagrant:vagrant /etc/containerd
sudo containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml


sudo systemctl restart containerd
sudo systemctl enable containerd



sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://dl.k8s.io/apt/doc/apt-key.gpg
sudo echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update

# 7. Installing kubelet, kubeadm, and kubectl

sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
sudo apt-get install -y kubelet=1.27.3-00 kubeadm=1.27.3-00 kubectl=1.27.3-00
sudo apt-mark hold kubelet kubeadm kubectl



