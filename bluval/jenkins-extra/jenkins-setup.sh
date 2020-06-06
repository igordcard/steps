#!/bin/bash

# extra steps to get jenkins to install/uninstall KUD on a pre-chosen set of nodes
# (choose this file and attached files depending on environment intended)

# customized aio.sh/installer.sh scripts based on your intentions
cp aio.sh /var/lib/jenkins/
cp installer.sh /var/lib/jenkins/
chown jenkins:jenkins /var/lib/jenkins/aio.sh
chown jenkins:jenkins /var/lib/jenkins/installer.sh

# make jenkins-rsa key visibile in jenkins by default (TODO: something was refreshing the key..)
cp /var/lib/jenkins/.ssh
cp ../jenkins-rsa id_rsa
chown jenkins:jenkins id_rsa

# provide the custom playbook to wipe out docker after uninstalling KUD (TODO: should be contributed to multicloud-k8s)
cp purge-docker.yml /var/lib/jenkins/
chown jenkins:jenkins /var/lib/jenkins/purge-docker.yml