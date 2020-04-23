#!/bin/bash

# bionic

rm -rf ~/.kube
sudo su
kubeadm reset
iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X
rm -rf ~/.kube

#if installed via apt:
apt-get remove -y kubelet kubeadm kubectl kubernetes-cni kube*  docker-ce docker-ce-cli

# if installed via ICN:
cd icn
make kud_bm_reset