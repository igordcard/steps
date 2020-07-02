#!/bin/bash

# run as root


git clone https://github.com/onap/multicloud-k8s.git

# prepare the vagrant vms for the cluster:
cd multicloud-k8s/kud/hosting_providers/containerized
cp -R testing testing2
cd testing
sed -i "s/\"ubuntu18\"/\"cluster-101\"/" Vagrantfile
sed -i "s/memory = 32768/memory = 16384/" Vagrantfile
sed -i "s/cpus = 16/cpus = 8/" Vagrantfile
sed -i "s/size = 400/size = 100/" Vagrantfile
vagrant up
export VAGRANT_IP_ADDR1=$(vagrant ssh-config | grep HostName | cut -f 4 -d " ")
ssh-copy-id -f -i ~/.ssh/id_rsa.pub -o "IdentityFile .vagrant/machines/default/libvirt/private_key" -o StrictHostKeyChecking=no vagrant@$VAGRANT_IP_ADDR1
ssh vagrant@$VAGRANT_IP_ADDR1 -t "sudo su -c 'mkdir /root/.ssh; cp /home/vagrant/.ssh/authorized_keys /root/.ssh/'"

cp Vagrantfile ../testing2/Vagrantfile
cd ../testing2
sed -i "s/\"ubuntu18\"/\"cluster-102\"/" Vagrantfile
vagrant up
export VAGRANT_IP_ADDR2=$(vagrant ssh-config | grep HostName | cut -f 4 -d " ")
ssh-copy-id -f -i ~/.ssh/id_rsa.pub -o "IdentityFile .vagrant/machines/default/libvirt/private_key" -o StrictHostKeyChecking=no vagrant@$VAGRANT_IP_ADDR2
ssh vagrant@$VAGRANT_IP_ADDR2 -t "sudo su -c 'mkdir /root/.ssh; cp /home/vagrant/.ssh/authorized_keys /root/.ssh/'"
cd
