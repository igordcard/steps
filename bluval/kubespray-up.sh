#!/bin/bash

# Kubernetes part

# prep k8s
# only do this 1 machine -> the master
#cd icn
#make kud_bm_deploy_mini
# 1.16 instead:
apt-get install -y git-review
git clone "https://gerrit.onap.org/r/multicloud/k8s"
cd k8s
ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa
git remote add gerrit ssh://igordcard@gerrit.onap.org:29418/multicloud/k8s.git
git review -s
git review -d 106869
# 1. set dns_min_replicas: 1:
# not needed anymore since we've switched to a 2-node deployment (1 master 2 worker)
# 2. remove cmk, ovn and virtlet groups
vim aio.sh
# 3. replace all localhost with $HOSTNAME: :%s/localhost/$HOSTNAME
sed -i 's/localhost/$HOSTNAME/' aio.sh
vim ../vagrant/installer.sh
# 4. in installer.sh, comment the following:
# install_addons
# if ${KUD_PLUGIN_ENABLED:-false}; then
#     install_plugin
# fi
# 5. because it's multi-node now, go back to modifying aio.sh:
vim aio.sh
# and add the worker node details to the [all] and [kube-node] groups, like (respectively):
# pod11-node2 ansible_ssh_host=10.10.110.22 ansible_ssh_port=22
# pod11-node2
# 6. before proceeding, make sure root logins are allowed between
# the nodes and that the public keys have been exchanged,
# and also SSH to localhost, then
# install kubernetes (ansible will automatically install it in the worker node)
./aio.sh