#!/bin/bash

# bionic

# make sure to delete weave before k8s or docker changes
# the following command may not be in the correct format right now:
kubectl delete -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
curl -L git.io/weave -o weave
chmod a+x weave
./weave reset

rm -rf ~/.kube
sudo su
kubeadm reset
iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X
ipvsadm --clear
rm -rf ~/.kube
rm -rf /etc/cni/net.d

#if installed via apt:
apt-get remove -y kubelet kubeadm kubectl kubernetes-cni kube*  docker-ce docker-ce-cli

# if installed via ICN:
cd icn
make kud_bm_reset

docker rmi -f $(docker image ls -a -q)
sudo apt-get purge docker-* -y --allow-change-held-packages

# etcdctl -C (...) member remove