#!/bin/bash

# extra steps to get jenkins to install/uninstall KUD on a pre-chosen set of nodes
# (choose this file and attached files depending on environment intended)

# customized aio.sh/installer.sh scripts based on your intentions
cp aio.sh /var/lib/jenkins/
cp installer.sh /var/lib/jenkins/
chown jenkins:jenkins /var/lib/jenkins/aio.sh
chown jenkins:jenkins /var/lib/jenkins/installer.sh

# make jenkins-rsa key visible in jenkins by default (TODO: something was refreshing the key..)
cd /var/lib/jenkins/.ssh
rm id_rsa*
cp ../jenkins-rsa id_rsa
chown jenkins:jenkins id_rsa