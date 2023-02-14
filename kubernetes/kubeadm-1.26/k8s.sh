#!/bin/bash
# run as root

# Ubuntu 20.04
# Docker 23
# Kubernetes 1.26

# uninstall old versions of docker
# ref: https://docs.docker.com/engine/install/ubuntu/
apt-get remove docker docker-engine docker.io containerd runc

# install docker using the convenience script
# ref: https://docs.docker.com/engine/install/ubuntu/
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
# Client: Docker Engine - Community
#  Version:           23.0.1
#  API version:       1.42
#  Go version:        go1.19.5
#  Git commit:        a5ee5b1
#  Built:             Thu Feb  9 19:46:56 2023
#  OS/Arch:           linux/amd64
#  Context:           default

# Server: Docker Engine - Community
#  Engine:
#   Version:          23.0.1
#   API version:      1.42 (minimum version 1.12)
#   Go version:       go1.19.5
#   Git commit:       bc3805a
#   Built:            Thu Feb  9 19:46:56 2023
#   OS/Arch:          linux/amd64
#   Experimental:     false
#  containerd:
#   Version:          1.6.16
#   GitCommit:        31aa4358a36870b21a992d3ad2bef29e1d693bec
#  runc:
#   Version:          1.1.4
#   GitCommit:        v1.1.4-0-g5fd4c4d
#  docker-init:
#   Version:          0.19.0
#   GitCommit:        de40ad0

# ================================================================================

# To run Docker as a non-privileged user, consider setting up the
# Docker daemon in rootless mode for your user:

#     dockerd-rootless-setuptool.sh install

# Visit https://docs.docker.com/go/rootless/ to learn about rootless mode.


# To run the Docker daemon as a fully privileged service, but granting non-root
# users access, refer to https://docs.docker.com/go/daemon-access/

# WARNING: Access to the remote API on a privileged Docker daemon is equivalent
#          to root access on the host. Refer to the 'Docker daemon attack surface'
#          documentation for details: https://docs.docker.com/go/attack-surface/

# ================================================================================

# prep proxy configs
# ref: https://docs.docker.com/config/daemon/systemd/
mkdir -p /usr/lib/systemd/system/docker.service.d/
vim /usr/lib/systemd/system/docker.service.d/http-proxy.conf
real_ip=`ifconfig IF | grep 'inet ' | cut -d: -f2 | awk '{ print $2}'`
# example:
# [Service]
# Environment="HTTP_PROXY=http://proxy.corp.com:911"
# Environment="HTTPS_PROXY=http://proxy.corp.com:911"
# Environment="FTP_PROXY=http://proxy.corp.com:911"
# Environment="NO_PROXY=localhost,127.0.0.1,127.0.1.1,10.96.0.0/12,192.168.0.0/16,$real_ip,.corp.com"
# Environment="http_proxy=http://proxy.corp.com:911"
# Environment="https_proxy=http://proxy.corp.com:911"
# Environment="ftp_proxy=http://proxy.corp.com:911"
# Environment="no_proxy=localhost,127.0.0.1,127.0.1.1,10.96.0.0/12,192.168.0.0/16,$real_ip,.corp.com"
systemctl daemon-reload
systemctl restart docker
systemctl show --property=Environment docker

# setup docker shim replacement (cri-dockerd)
# ref: https://github.com/Mirantis/cri-dockerd
wget https://storage.googleapis.com/golang/getgo/installer_linux
chmod +x ./installer_linux
./installer_linux
source ~/.bash_profile
git clone https://github.com/Mirantis/cri-dockerd.git
cd cri-dockerd
mkdir bin
go build -o bin/cri-dockerd
mkdir -p /usr/local/bin
install -o root -g root -m 0755 bin/cri-dockerd /usr/local/bin/cri-dockerd
cp -a packaging/systemd/* /etc/systemd/system
sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service
systemctl daemon-reload
systemctl enable cri-docker.service
systemctl enable --now cri-docker.socket
ls -l /var/run/cri-dockerd.sock

# take note of node uuids
cat /sys/class/dmi/id/product_uuid
cat /etc/machine-id

# install kubeadm
# ref: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

apt-get update
apt-get install -y apt-transport-https ca-certificates curl
mkdir /etc/apt/keyring
chmod 755 /etc/apt/keyrings
curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-mark unhold kubelet kubeadm kubectl
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# configure cgroup driver
# ref: https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/configure-cgroup-driver/
# don't do anything, leave it at default cgroup driver of systemd

# proxy stuff for kubelet
mkdir -p /usr/lib/systemd/system/kubelet.service.d/
cp /usr/lib/systemd/system/docker.service.d/http-proxy.conf /usr/lib/systemd/system/kubelet.service.d/http-proxy.conf
systemctl daemon-reload
systemctl restart kubelet
systemctl restart docker
systemctl show --property=Environment docker

# if using nodus, stop & disable ufw first
ufw disable

# disable swap - this is a necessary step for kubelet!
swapoff -a
vim /etc/fstab

# finally create cluster
# ref: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/
# ref: https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-config/

#kubeadm config print init-defaults

# install k8s (with calico)
kubeadm config images pull --cri-socket unix:///var/run/cri-dockerd.sock # --v=5
kubeadm init --pod-network-cidr=192.168.0.0/16 --cri-socket unix:///var/run/cri-dockerd.sock

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
export KUBECONFIG=$HOME/.kube/config
echo "export KUBECONFIG=$HOME/.kube/config" >> /root/.bashrc
nodename=$(kubectl get node -o jsonpath='{.items[0].metadata.name}')
kubectl taint node $nodename node-role.kubernetes.io/master:NoSchedule-
kubectl taint node $nodename node-role.kubernetes.io/control-plane:NoSchedule-
kubectl taint node $nodename node.kubernetes.io/not-ready:NoSchedule-
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
kubectl taint nodes --all node-role.kubernetes.io/master-

# install calico
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/tigera-operator.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/custom-resources.yaml
watch kubectl get pods -n calico-system
kubectl get nodes -o wide
systemctl restart kubelet

# check what the final kubeadm config is
kubectl -n kube-system get cm kubeadm-config -o yaml
# apiVersion: v1
# data:
#   ClusterConfiguration: |
#     apiServer:
#       extraArgs:
#         authorization-mode: Node,RBAC
#       timeoutForControlPlane: 4m0s
#     apiVersion: kubeadm.k8s.io/v1beta3
#     certificatesDir: /etc/kubernetes/pki
#     clusterName: kubernetes
#     controllerManager: {}
#     dns: {}
#     etcd:
#       local:
#         dataDir: /var/lib/etcd
#     imageRepository: registry.k8s.io
#     kind: ClusterConfiguration
#     kubernetesVersion: v1.26.1
#     networking:
#       dnsDomain: cluster.local
#       podSubnet: 192.168.0.0/16
#       serviceSubnet: 10.96.0.0/12
#     scheduler: {}
# kind: ConfigMap
# metadata:
#   creationTimestamp: "2023-02-14T01:44:03Z"
#   name: kubeadm-config
#   namespace: kube-system
#   resourceVersion: "199"
#   uid:

# install helm
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# to destroy
kubeadm reset --cri-socket unix:///var/run/cri-dockerd.sock # --force
rm -rf /etc/cni/net.d
rm -rf /etc/kubernetes