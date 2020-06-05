#!/bin/bash

# Kubernetes part
# >> For all other nodes, make sure to generate SSH keys and cross-copy them to authorized_keys

# prep k8s
# only do this 1 machine -> the master
#cd icn
#make kud_bm_deploy_mini
git clone "https://gerrit.onap.org/r/multicloud/k8s"
cd k8s
ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa # maybe it was already done in jenkins-bluval.sh
# >> copy public key to onap gerrit

# 1. replace all localhost with $HOSTNAME: :%s/localhost/$HOSTNAME
sed -i 's/localhost/$HOSTNAME/' kud/hosting_providers/baremetal/aio.sh

# 2. remove cmk, ovn and virtlet groups
# 3. because it's multi-node now, also modify in aio.sh:
# and add the worker node details to the [all] and [kube-node] groups, like (respectively):
# pod14-node5 ansible_ssh_host=10.10.140.25 ansible_ssh_port=22
# pod14-node5
vim kud/hosting_providers/baremetal/aio.sh

# 4. in installer.sh, comment the following:
# install_addons
# if ${KUD_PLUGIN_ENABLED:-false}; then
#     install_plugin
# fi
vim kud/hosting_providers/vagrant/installer.sh

# 5. before proceeding, make sure root logins are allowed between
# the nodes and that the public keys have been exchanged,
# and also SSH to localhost, then
# install kubernetes (ansible will automatically install it in the worker node)
kud/hosting_providers/baremetal/aio.sh