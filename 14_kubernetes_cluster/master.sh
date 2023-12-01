#!/bin/bash


kubeadm config images pull

sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --control-plane-endpoint=master.example.com --ignore-preflight-errors=all  --apiserver-advertise-address=192.168.56.101


# Configure kubeconfig for the master
mkdir -p /home/vagrant/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown vagrant:vagrant /home/vagrant/.kube/config

sudo ufw allow 6443


curl -o kube-flannel.yml https://raw.githubusercontent.com/coreos/flannel/v0.9.1/Documentation/kube-flannel.yml
sudo sed -i.bak 's|"/opt/bin/flanneld",|"/opt/bin/flanneld", "--iface=enp0s8",|' kube-flannel.yml
kubectl apply -f kube-flannel.yml

sudo systemctl daemon-reload
sudo systemctl restart kubelet
sudo systemctl enable kubelet

sleep 10

kubectl get pods -A


sudo kubeadm token create --print-join-command > /vagrant/join-worker.sh
chmod +x /vagrant/join-worker.sh
