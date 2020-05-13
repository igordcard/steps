#!/bin/bash

# bionic

cd
sudo su -c "cat > /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF"

sudo modprobe overlay
sudo modprobe br_netfilter

sudo su -c "cat > /etc/sysctl.d/99-kubernetes-cri.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF"

sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
sudo update-alternatives --set arptables /usr/sbin/arptables-legacy
sudo update-alternatives --set ebtables /usr/sbin/ebtables-legacy

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# install docker-ce manually

sudo apt-get remove -y docker docker-engine docker.io containerd runc
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
sudo apt-mark unhold docker-ce docker-ce-cli
sudo apt-get install -y docker-ce=5:18.09.9~3-0~ubuntu-bionic docker-ce-cli=5:18.09.9~3-0~ubuntu-bionic containerd.io build-essential
sudo apt-mark hold docker-ce docker-ce-cli

sudo su -c 'cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF'

sudo mkdir -p /etc/systemd/system/docker.service.d

sudo systemctl daemon-reload
sudo systemctl restart docker

sudo usermod -a -G docker $USER

# k8s setup

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo su -c "cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF"
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

sudo swapoff /swap.img # or replace with path to swap file/partition
sudo kubeadm config images pull
sudo kubeadm init
# kubeadm join 10.54.77.117:6443 --token pincbq.aq6oc71rd5d3cv42 --discovery-token-ca-cert-hash sha256:9ef75ac1150bed928ba6fbb5c32edcec049ec79fbeccbd5e46e55033848bb075 # sample

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown -R $(id -u):$(id -g) $HOME/.kube/config

kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
kubectl taint node $HOSTNAME node-role.kubernetes.io/master:NoSchedule-