#!/bin/bash

# first get k8s up and running with kubeadm1
# kubeadm-up.sh

# prepare k8s node

# the bpa_op_install make build relies on hardcoded root access to the root's private key:
sudo su

git clone https://github.com/akraino-edge-stack/icn.git
cd icn
# make sure there is a ~/.kube
ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
#kubectl taint nodes kubeadm3 node-role.kubernetes.io/master:NoSchedule-
#kubectl taint nodes kubeadm3 node.kubernetes.io/not-ready:NoSchedule-

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
make bpa_op_install

cd
tar -xf vagrant-e2e-20200420.tar.gz
cd vagrant_e2e
kubectl create -f "https://raw.githubusercontent.com/metal3-io/baremetal-operator/master/deploy/crds/metal3.io_baremetalhosts_crd.yaml"
./setup.sh -p libvirt
vagrant plugin install vagrant-proxyconf

# the following comes from bpa_e2e_test.sh
apt-get update
apt-get install -y vagrant virtualbox
cp fake_dhcp_lease /opt/icn/dhcp/dhcpd.leases # this is where ICN looks for dhcp leases
kubectl apply -f bmh-bpa-test.yaml
cat /root/.ssh/id_rsa.pub > vm_authorized_keys # define proxy through environment even if chameleonsocks already running
# this is because the vagrant vm will not use chameleonsocks by default
export http_proxy=http://proxy.company.com:911
export https_proxy=http://proxy.company.com:911
export no_proxy=localhost,127.0.0.1
export HTTP_PROXY=$http_proxy
export HTTPS_PROXY=$https_proxy
export NO_PROXY=$no_proxy
vagrant up
unset http_proxy
unset https_proxy
unset HTTP_PROXY
unset HTTPS_PROXY
unset no_proxy
unset NO_PROXY
sleep 5
ssh-keygen -f "/root/.ssh/known_hosts" -R "192.168.50.63"
kubectl apply -f e2e_test_provisioning_cr.yaml
kubectl apply -f e2e_test_software_cr.yaml # added by me

# access VM
# vagrant ssh bpa-test-vm -- -i ~/.ssh/id_rsa

# 20200423: THIS DOESN'T ACTUALLY WORK, DNS ISSUES INSIDE VAGRANT VM with docker

# uninstall
make bpa_op_delete
kubectl delete secret ssh-key-secret
# and others
#kubectl delete secret ssh-key-secret # created by make bpa_op_install
kubectl delete -f e2e_test_software_cr.yaml
kubectl delete -f e2e_test_provisioning_cr.yaml
kubectl delete job kud-cluster-test
#kubectl delete deployment bpa-operator
vagrant destroy -f
#virsh destroy vagrant_e2e_bpa-test*
#virsh undefine vagrant_e2e_bpa-test*
# and others
cd ~/icn
make bpa_op_delete
