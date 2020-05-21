#!/bin/bash

# warning: forked off jenkins-bluval.sh on
# 20200521 but likely won't be updated again

# requirements:
# - host that doesn't need proxy configs anymore
# - use root user

apt-get install -y python build-essential python-bashate # dependencies for icn job
wget https://bootstrap.pypa.io/get-pip.py
python2 get-pip.py
git clone "https://gerrit.akraino.org/r/icn"


cd ci
sed -i "s/2.192/\"2.237\"/" vars.yaml
./install_ansible.sh
pip install -U ansible # otherwise will fail on jenkins plugins download
ansible-playbook site_jenkins.yaml --extra-vars "@vars.yaml" -vvv

echo "machine nexus.akraino.org login icn.jenkins password icngroup" | sudo tee /var/lib/jenkins/.netrc

cd
git clone --recursive "https://gerrit.akraino.org/r/ci-management"
#git clone "https://gerrit.akraino.org/r/icn"
mkdir -p ~/.config/jenkins_jobs

cat << EOF | tee ~/.config/jenkins_jobs/jenkins_jobs.ini
[job_builder]
ignore_cache=True
keep_descriptions=False
recursive=True
retain_anchors=True
update=jobs

[jenkins]
user=admin
password=admin
url=http://localhost:8080
EOF

# assume pharos pod11-node3
# add the jenkins-ssh key to Jenkins via the web UI: http://10.10.110.23:8080/credentials/store/system/domain/_/newCredentials
# SSH Username with private key
# ID: jenkins-ssh
# Username: icn.jenkins
# Private key: <copy from /root/.ssh/id_rsa>
# and then add respective public key to gerrit.akraino.org

# and put the private key where it can be accessed by jenkins [ideally a fresh one should be created at this point]
# this is the CLUSTER_SSH_KEY -> CLUSTER_SSH_KEY=/var/lib/jenkins/jenkins-rsa
cp /root/.ssh/id_rsa /var/lib/jenkins/jenkins-rsa
chown jenkins:jenkins /var/lib/jenkins/jenkins-rsa
# these are not very secure ways! for production you shouldn't leak root private key like this!

pip install jenkins-job-builder
# or just $ jenkins-jobs test/update, if you logout and login again
# after installing jenkins-jobs and before the following commands:
python2 -m jenkins_jobs test ci-management/jjb:icn/ci/jjb icn-master-verify
python2 -m jenkins_jobs update ci-management/jjb:icn/ci/jjb icn-master-verify

# install the Rebuilder plugin to easily rebuild a job with the same/similar parameters:
# Go to: http://10.10.110.23:8080/pluginManager/available and install "Rebuilder"
systemctl restart jenkins

# if docker is needed, let jenkins access docker
usermod -aG docker jenkins

pip3 install lftools # to upload logs to nexus, if needed