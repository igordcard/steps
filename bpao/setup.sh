#!/bin/bash

# install kubeadm

# prepare k8s node
su
git clone https://github.com/akraino-edge-stack/icn.git
cd icn
# make sure there is a ~/.kube
ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
make bpa_op_install
kubectl taint nodes kubeadm3 node-role.kubernetes.io/master:NoSchedule-
kubectl taint nodes kubeadm3 node.kubernetes.io/not-ready:NoSchedule-

cd
tar -xf vagrant-e2e-20200420.tar.gz
cd vagrant_e2e
kubectl create -f "https://github.com/metal3-io/baremetal-operator/blob/master/deploy/crds/metal3.io_baremetalhosts_crd.yaml"
./bpa_e2e_test.sh

# uninstall
make bpa_op_delete
