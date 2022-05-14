#!/bin/bash

# run as root
# Ubuntu 20.04

# going from containerd/crictl back to docker

systemctl stop kubelet
systemctl stop containerd
systemctl status kubelet

apt-get update
apt-get remove containerd
apt-get autoremove containerd
apt-get purge containerd
apt-get autoremove --purge containerd

mv /etc/containerd /etc/containerd.bak

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
kvm-intel
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

rm /etc/sysctl.d/k8s.conf

sysctl --system

mkdir /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "insecure-registries" : ["192.168.121.1:5000","192.168.122.1:5000"]
}
EOF

apt-get install -y docker docker.io build-essential apt-transport-https ca-certificates curl gnupg-agent software-properties-common

docker ps

# re-run kubeadm init
