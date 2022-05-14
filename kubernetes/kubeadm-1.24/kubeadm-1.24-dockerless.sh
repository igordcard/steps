#!/bin/bash

# run as root
# Ubuntu 20.04

# kubeadm/k8s 1.24 brought about the end of dockershim, as such, a few side effects have ensued
# so let's start by prepping a few things on the host ahead of deploying kubeadm:
systemctl stop kubelet
systemctl stop containerd
systemctl status kubelet
apt-get update
apt purge docker-ce docker-ce-cli
apt-get install -y containerd

mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml

vim /etc/containerd/config.toml
# in the config look up "containerd.runtimes.runc.options"/"SystemdCgroup" and set as such:
          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
            SystemdCgroup = true

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

echo "runtime-endpoint: unix:///run/containerd/containerd.sock" > /etc/crictl.yaml

systemctl start containerd

crictl ps

# Start containerd
systemctl enable --now containerd

# if kubeadm already running by any chance, do this too:
vim /etc/sysconfig/kubelet
  # add the following flags to KUBELET_KUBEADM_ARGS variable:
    KUBELET_KUBEADM_ARGS="... --container-runtime=remote --container-runtime-endpoint=/run/containerd/containerd.sock"
systemctl start kubelet

# at this point, kubeadm 1.24 + CNIs should finally work again, and so should EMCO
# if you're used to using the `docker` command for CLI operations, now you need to use `crictl`
