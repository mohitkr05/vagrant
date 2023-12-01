If you are working in DevOps and trying to learn more about Kubernetes, the first step is to install it locally and create a test cluster.

Kubernetes, the industry-leading container orchestration tool, offers a robust solution for automating deployment, scaling, and management. If you're an Ubuntu 22.04 (Jammy Jellyfish) user eager to harness the power of Kubernetes, you're in the right place.

This blog post serves as a comprehensive guide, taking you through the step-by-step process of installing Kubernetes on Ubuntu 22.04.

## Kubernetes Cluster overview

A Kubernetes cluster contains multiple compute, referred to as nodes, that work together to run containerized applications efficiently and reliably.
It provides a platform for managing and orchestrating containers at scale.A cluster consists of a control plane and one or more worker nodes.

![](https://bucket-gmhbbh.s3.ap-south-1.amazonaws.com/wp-content/uploads/2023/07/12130102/Kubernetes-cluster.drawio.png)

### Control Plane

The control plane, also known as the master node, is responsible for managing and coordinating the cluster's operations. It oversees tasks such as scheduling containers, maintaining desired state, scaling applications, and handling communication within the cluster. The control plane components include:

- kube-apiserver: Exposes the Kubernetes API, which allows users and other components to interact with the cluster.
- kube-controller-manager: Manages various controllers responsible for maintaining the desired state of the cluster, such as node, pod, and service controllers.
- kube-scheduler: Assigns pods to nodes based on resource availability and scheduling policies.
- etcd: Stores the cluster's configuration data and maintains the state of the entire cluster. It provides high availability and consistency to ensure fault tolerance.

### Worker nodes

Worker nodes, also called minion nodes, are where containers are deployed and run. They perform the actual workload and execute tasks assigned by the control plane. Each worker node consists of the following components:

- kubelet: Runs on each node and communicates with the control plane. It manages the node's containers, ensuring they are running as expected.
- kube-proxy: Routes network traffic to the appropriate containers by maintaining network rules and load balancing.
- Container runtime: This can be Docker or another container runtime, responsible for pulling container images, creating and managing containers, and handling container lifecycles.


### Networking

- In addition to the control plane and worker nodes, a Kubernetes cluster often includes a networking solution and a storage solution. 
- These additional components enable communication between pods, provide network policies, and offer persistent storage for applications running in the cluster.
- Networking solutions, such as Calico, Flannel, or Cilium, facilitate pod-to-pod and external network communication within the cluster. They ensure that containers running on different nodes can communicate with each other seamlessly.
- Storage solutions, such as local storage, network-attached storage (NAS), or cloud storage, provide persistent storage for applications. They enable data persistence and allow applications to access and store data beyond the lifespan of a pod or container.

By understanding the components and their roles within a Kubernetes cluster, you can better appreciate the distributed architecture and the collaborative nature of managing containerized applications at scale.


## Installing Kubernetes cluster on Ubuntu 22.04

The cluster will contain the master node and worker nodes, most of the configuration for both the nodes are common with some additional configuration for the master node.

The configuration will have the following nodes

- Master Node:  192.168.56.101 – master.example.com
- First Worker Node:  192.168.56.111 – worker1.example.com
- Second Worker Node:  192.168.56.112 – worker2.example.com

1. For interworking, all the three nodes will have the configuration in the `/etc/hosts` file.

```
192.168.56.101   master.example.com   master
192.168.56.111   worker1.example.com worker1
192.168.56.112   worker2.example.com worker2
```

2. Disabling swap

```
swapoff -a
sudo sed -i '/ swap/d' /etc/fstab
```

3. Load the following kernel modules on all the nodes

```
sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter
```
4. Set the following Kernel parameters for Kubernetes

```
sudo tee /etc/sysctl.d/99-kubernetes-cri.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
```
Implement the above using the `sudo sysctl --system`

4. Install Docker and containerd.io

```
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
```

5. Configure containerd so that it starts using systemd as cgroup.

```
sudo mkdir -p /etc/containerd/
sudo chown vagrant:vagrant /etc/containerd
sudo containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
```

6. Restart and enable containerd service

```
sudo systemctl restart containerd
sudo systemctl enable containerd

```

7. Add apt repository for Kubernetes.1.27

```

sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://dl.k8s.io/apt/doc/apt-key.gpg
sudo echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update


sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
sudo apt-get install -y kubelet=1.27.3-00 kubeadm=1.27.3-00 kubectl=1.27.3-00
sudo apt-mark hold kubelet kubeadm kubectl


kubeadm config images pull
```


### Master node


1. Initialize Kubernetes cluster with Kubeadm command

Now to initialize Kubernetes cluster. Run the following Kubeadm command from the master node only.

```
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --control-plane-endpoint=master.example.com --ignore-preflight-errors=all
```

2. Configure kubeconfig for the master

```
mkdir -p /home/vagrant/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown vagrant:vagrant /home/vagrant/.kube/config
```

3. Configure flannel

```
curl -o kube-flannel.yml https://raw.githubusercontent.com/coreos/flannel/v0.9.1/Documentation/kube-flannel.yml
sudo sed -i.bak 's|"/opt/bin/flanneld",|"/opt/bin/flanneld", "--iface=enp0s9",|' kube-flannel.yml
kubectl apply -f kube-flannel.yml

sudo systemctl daemon-reload
sudo systemctl restart kubelet

```

## Worker node


- Use the join command to add the node to the cluster


