#!/bin/bash

# Install Docker
apt-get update
apt-get install -y docker.io

# Install Kubernetes components
apt-get update && apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet kubeadm kubectl

# Join worker node to the Kubernetes cluster
# kubeadm join 192.168.50.10:6443 --token <token> --discovery-token-ca-cert-hash <hash>
