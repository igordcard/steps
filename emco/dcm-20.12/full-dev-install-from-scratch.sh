#!/bin/bash

# run as root

MK8S_REMOTE="https://github.com/onap/multicloud-k8s.git"
MK8S_DIR=~/multicloud-k8s

git clone $MK8S_REMOTE

apt-get install vagrant -y
$MK8S_DIR/kud/hosting_providers/vagrant/setup.sh -p libvirt

# template sample vagrant clusters:
cd $MK8S_DIR/kud/hosting_providers/containerized/
cp -R testing cluster01
cp -R testing cluster02
cp -R testing cluster03

# prepare the 1st vagrant VM cluster:
cd $MK8S_DIR/kud/hosting_providers/containerized/cluster01
sed -i "s/\"ubuntu18\"/\"cluster01\"/" Vagrantfile
sed -i "s/memory = 32768/memory = 10248/" Vagrantfile
sed -i "s/cpus = 16/cpus = 2/" Vagrantfile
sed -i "s/size = 400/size = 30/" Vagrantfile
vagrant up

export VAGRANT_IP_ADDR1=$(vagrant ssh-config | grep HostName | cut -f 4 -d " ")
sed -i '/VAGRANT_IP_ADDR1/d' ~/.bashrc
echo "export VAGRANT_IP_ADDR1=$VAGRANT_IP_ADDR1" >> ~/.bashrc
ssh-copy-id -f -i ~/.ssh/id_rsa.pub -o "IdentityFile .vagrant/machines/default/libvirt/private_key" -o StrictHostKeyChecking=no vagrant@$VAGRANT_IP_ADDR1
ssh vagrant@$VAGRANT_IP_ADDR1 -t "sudo su -c 'mkdir /root/.ssh; cp /home/vagrant/.ssh/authorized_keys /root/.ssh/'"

# SEE(INSIDE-VAGRANT)

# prepare the 2nd vagrant VM cluster:
cd $MK8S_DIR/kud/hosting_providers/containerized/cluster02
sed -i "s/\"ubuntu18\"/\"cluster02\"/" Vagrantfile
sed -i "s/memory = 32768/memory = 10248/" Vagrantfile
sed -i "s/cpus = 16/cpus = 2/" Vagrantfile
sed -i "s/size = 400/size = 30/" Vagrantfile
vagrant up

export VAGRANT_IP_ADDR2=$(vagrant ssh-config | grep HostName | cut -f 4 -d " ")
sed -i '/VAGRANT_IP_ADDR2/d' ~/.bashrc
echo "export VAGRANT_IP_ADDR2=$VAGRANT_IP_ADDR2" >> ~/.bashrc
ssh-copy-id -f -i ~/.ssh/id_rsa.pub -o "IdentityFile .vagrant/machines/default/libvirt/private_key" -o StrictHostKeyChecking=no vagrant@$VAGRANT_IP_ADDR2
ssh vagrant@$VAGRANT_IP_ADDR2 -t "sudo su -c 'mkdir /root/.ssh; cp /home/vagrant/.ssh/authorized_keys /root/.ssh/'"

# SEE(INSIDE-VAGRANT)

#####

# if vars lost:
cd
cd $MK8S_DIR/kud/hosting_providers/containerized/cluster01
export VAGRANT_IP_ADDR1=$(vagrant ssh-config | grep HostName | cut -f 4 -d " ")
cd $MK8S_DIR/kud/hosting_providers/containerized/cluster02
export VAGRANT_IP_ADDR2=$(vagrant ssh-config | grep HostName | cut -f 4 -d " ")


# ===========================
# inside each of the clusters
# REF(INSIDE-VAGRANT)

ssh root@$VAGRANT_IP_ADDR1

ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa

MK8S_REMOTE="https://github.com/onap/multicloud-k8s.git"
MK8S_DIR=~/multicloud-k8s

git clone $MK8S_REMOTE
cd $MK8S_DIR

# install kubernetes/docker using KUD AIO (global cluster):
sed -i 's/^localhost/$HOSTNAME/' kud/hosting_providers/baremetal/aio.sh

# >> disable addons:
vim kud/hosting_providers/vagrant/installer.sh
# comment the following lines:

#install_addons
#if ${KUD_PLUGIN_ENABLED:-false}; then
#    install_plugin
#fi

# deploy KUD
kud/hosting_providers/baremetal/aio.sh

exit

#####

# repeat the above but for:
ssh root@$VAGRANT_IP_ADDR2
# SEE(INSIDE-VAGRANT)

# ===========================
# back out to the main host
# REF(INSTALL-EMCO)

