#!/bin/bash

# extra steps to get jenkins to install/uninstall KUD on a pre-chosen set of nodes
# (choose this file and attached files depending on environment intended)

cp aio.sh /var/lib/jenkins/
cp installer.sh /var/lib/jenkins/
chown jenkins:jenkins /var/lib/jenkins/aio.sh
chown jenkins:jenkins /var/lib/jenkins/installer.sh

cp /var/lib/jenkins/.ssh
cp ../jenkins-rsa id_rsa
chown jenkins:jenkins id_rsa