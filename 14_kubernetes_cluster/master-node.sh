#!/bin/bash

# Pull images so that init is quick

kubeadm config images pull

# Initialize Kubernetes master
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --control-plane-endpoint=master.kube.cluster --ignore-preflight-errors=all

# Configure kubeconfig for the master
mkdir -p /home/vagrant/.kube
cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown vagrant:vagrant /home/vagrant/.kube/config


# Fix kubelet IP
echo 'Environment="KUBELET_EXTRA_ARGS=--node-ip=192.168.56.10"' | sudo tee -a /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

# Configure flannel
curl -o kube-flannel.yml https://raw.githubusercontent.com/coreos/flannel/v0.9.1/Documentation/kube-flannel.yml
sed -i.bak 's|"/opt/bin/flanneld",|"/opt/bin/flanneld", "--iface=enp0s8",|' kube-flannel.yml
kubectl apply -f kube-flannel.yml


sudo systemctl daemon-reload
sudo systemctl restart kubelet