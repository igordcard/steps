#!/bin/bash

# remove k8s
cd icn
sudo make kud_bm_reset
#sudo make clean_all

# remove kubespray from multicloud-k8s:
cd k8s/kud/hosting_providers/vagrant
ansible-playbook -i inventory/hosts.ini /opt/kubespray-2.12.6/reset.yml --become --become-user=root -e reset_confirmation=yes 
