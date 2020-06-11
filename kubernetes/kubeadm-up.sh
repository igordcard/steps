#!/bin/bash

# bionic

cd

sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
sudo update-alternatives --set arptables /usr/sbin/arptables-legacy
sudo update-alternatives --set ebtables /usr/sbin/ebtables-legacy

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# install docker-ce manually using install-docker.sh
# #######

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

kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')" # kubespray kud uses Flannel
kubectl taint node $HOSTNAME node-role.kubernetes.io/master:NoSchedule-