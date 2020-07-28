#!/bin/bash

# run as root


git clone https://github.com/onap/multicloud-k8s.git

# prepare the vagrant vms for the cluster:
cd multicloud-k8s/kud/hosting_providers/containerized
cp -R testing testing2
cp -R testing testing3
cd testing
sed -i "s/\"ubuntu18\"/\"cluster-101\"/" Vagrantfile
sed -i "s/memory = 32768/memory = 16384/" Vagrantfile # warning: increase RAM if you'll use the kud job
sed -i "s/cpus = 16/cpus = 10/" Vagrantfile
sed -i "s/size = 400/size = 100/" Vagrantfile
vagrant up
export VAGRANT_IP_ADDR1=$(vagrant ssh-config | grep HostName | cut -f 4 -d " ")
sed -i '/VAGRANT_IP_ADDR1/d' ~/.bashrc
echo "export VAGRANT_IP_ADDR1=$VAGRANT_IP_ADDR1" >> ~/.bashrc
ssh-copy-id -f -i ~/.ssh/id_rsa.pub -o "IdentityFile .vagrant/machines/default/libvirt/private_key" -o StrictHostKeyChecking=no vagrant@$VAGRANT_IP_ADDR1
ssh vagrant@$VAGRANT_IP_ADDR1 -t "sudo su -c 'mkdir /root/.ssh; cp /home/vagrant/.ssh/authorized_keys /root/.ssh/'"
cp Vagrantfile ../testing2/Vagrantfile

cd ../testing2
sed -i "s/\"cluster-101\"/\"cluster-102\"/" Vagrantfile
vagrant up
export VAGRANT_IP_ADDR2=$(vagrant ssh-config | grep HostName | cut -f 4 -d " ")
sed -i '/VAGRANT_IP_ADDR2/d' ~/.bashrc
echo "export VAGRANT_IP_ADDR2=$VAGRANT_IP_ADDR2" >> ~/.bashrc
ssh-copy-id -f -i ~/.ssh/id_rsa.pub -o "IdentityFile .vagrant/machines/default/libvirt/private_key" -o StrictHostKeyChecking=no vagrant@$VAGRANT_IP_ADDR2
ssh vagrant@$VAGRANT_IP_ADDR2 -t "sudo su -c 'mkdir /root/.ssh; cp /home/vagrant/.ssh/authorized_keys /root/.ssh/'"
cp Vagrantfile ../testing3/Vagrantfile

cd ../testing3
sed -i "s/\"cluster-101\"/\"cluster-103\"/" Vagrantfile
vagrant up
export VAGRANT_IP_ADDR3=$(vagrant ssh-config | grep HostName | cut -f 4 -d " ")
sed -i '/VAGRANT_IP_ADDR3/d' ~/.bashrc
echo "export VAGRANT_IP_ADDR3=$VAGRANT_IP_ADDR3" >> ~/.bashrc
ssh-copy-id -f -i ~/.ssh/id_rsa.pub -o "IdentityFile .vagrant/machines/default/libvirt/private_key" -o StrictHostKeyChecking=no vagrant@$VAGRANT_IP_ADDR3
ssh vagrant@$VAGRANT_IP_ADDR3 -t "sudo su -c 'mkdir /root/.ssh; cp /home/vagrant/.ssh/authorized_keys /root/.ssh/'"
cd

# if vars lost:
cd
pushd ~/multicloud-k8s/kud/hosting_providers/containerized/testing
export VAGRANT_IP_ADDR1=$(vagrant ssh-config | grep HostName | cut -f 4 -d " ")
cd ../testing2
export VAGRANT_IP_ADDR2=$(vagrant ssh-config | grep HostName | cut -f 4 -d " ")
cd ../testing3
export VAGRANT_IP_ADDR3=$(vagrant ssh-config | grep HostName | cut -f 4 -d " ")
popd
