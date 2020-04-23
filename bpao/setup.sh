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

#./bpa_e2e_test.sh
apt-get update
apt-get install -y vagrant virtualbox
cp fake_dhcp_lease /opt/icn/dhcp/dhcpd.leases # this is where ICN looks for dhcp leases
kubectl apply -f bmh-bpa-test.yaml
cat /root/.ssh/id_rsa.pub > vm_authorized_keys
vagrant up
sleep 5
ssh-keygen -f "/root/.ssh/known_hosts" -R "192.168.50.63"
kubectl apply -f e2e_test_provisioning_cr.yaml

kubectl apply -f e2e_test_software_cr.yaml # added by mew

# access VM
# vagrant ssh bpa-test-vm -- -i ~/.ssh/id_rsa


# uninstall
make bpa_op_delete
kubectl delete secret ssh-key-secret
# and others
make bpa_op_delete
