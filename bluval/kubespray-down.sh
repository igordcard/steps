#!/bin/bash

## remove k8s
#cd icn
#sudo make kud_bm_reset
##sudo make clean_all

git clone "https://gerrit.onap.org/r/multicloud/k8s"

# remove kubespray from multicloud-k8s:
cd k8s/kud/hosting_providers/vagrant
ansible-playbook -i inventory/hosts.ini /opt/kubespray-2.12.6/reset.yml --become --become-user=root -e reset_confirmation=yes 

# do the following on >>all of the k8s nodes<<:
# To do this from Ansible, check file /opt/kubespray-2.12.6/roles/reset/tasks/main.yml, line 50 - it should have a task to delete images
# Then, contribute that as a patch.
#docker rmi -f $(docker image ls -a -q)
docker image ls -a -q | xargs -r docker rmi -fv # ansible friendly
sudo apt-get purge docker-* -y --allow-change-held-packages


# However, kubespray is a kubernetes-sigs project, so I need to do this a different way
# TODO
- name: reset | remove all docker images
  shell: "{{ docker_bin_dir }}/docker image ls -a -q | xargs -r docker rmi -fv"
  register: remove_all_images
  retries: 4
  until: remove_all_images.rc == 0
  delay: 5
  when: container_manager == "docker"
  tags:
    - docker
