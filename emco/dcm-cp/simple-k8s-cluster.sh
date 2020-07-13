#!/bin/bash

# run as root

ssh root@$VAGRANT_IP_ADDR1
ssh root@$VAGRANT_IP_ADDR2
# this is for a single cluster in a single machine

ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa

git clone https://github.com/onap/multicloud-k8s.git
cd multicloud-k8s

# install kubernetes/docker using KUD AIO (global cluster):
sed -i 's/localhost/$HOSTNAME/' kud/hosting_providers/baremetal/aio.sh

# >> disable addons:
vim kud/hosting_providers/vagrant/installer.sh
#install_addons
#if ${KUD_PLUGIN_ENABLED:-false}; then
#    install_plugin
#fi

# deploy KUD
kud/hosting_providers/baremetal/aio.sh