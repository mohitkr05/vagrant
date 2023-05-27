# https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
#!/bin/bash

# Initialize Kubernetes master
kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=10.10.0.10

# Configure kubeconfig for the master
mkdir -p /home/vagrant/.kube
cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown vagrant:vagrant /home/vagrant/.kube/config


# Fix kubelet IP
echo 'Environment="KUBELET_EXTRA_ARGS=--node-ip=10.0.0.10"' | sudo tee -a /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

# Configure flannel
curl -o kube-flannel.yml https://raw.githubusercontent.com/coreos/flannel/v0.9.1/Documentation/kube-flannel.yml
sed -i.bak 's|"/opt/bin/flanneld",|"/opt/bin/flanneld", "--iface=enp0s8",|' kube-flannel.yml
kubectl create -f kube-flannel.yml


sudo systemctl daemon-reload
sudo systemctl restart kubelet