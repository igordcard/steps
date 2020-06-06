#!/bin/bash
set -e
set -o errexit
set -o pipefail

echo "[ICN] Uninstalling EMCO k8s"
cd k8s/kud/hosting_providers/vagrant
ansible-playbook -i inventory/hosts.ini /opt/kubespray-2.12.6/reset.yml --become --become-user=root -e reset_confirmation=yes 

echo "[ICN] Purging Docker fully"
cp ~/purge-docker.yml .
ansible-playbook -i inventory/hosts.ini purge-docker.yml --become --become-user=root