#!/bin/bash

# requirements:
# - host that doesn't need proxy configs anymore
# - use root user

# Jenkins part

apt-get install -y python build-essential python-bashate # dependencies for icn job
wget https://bootstrap.pypa.io/get-pip.py
python2 get-pip.py
git clone "https://gerrit.akraino.org/r/icn"


cd icn/ci
sed -i "s/2.192/\"2.238\"/" vars.yaml
./install_ansible.sh
pip install -U ansible # otherwise will fail on jenkins plugins download
ansible-playbook site_jenkins.yaml --extra-vars "@vars.yaml" -vvv

echo "machine nexus.akraino.org login icn.jenkins password icngroup" | tee /var/lib/jenkins/.netrc

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

# add the jenkins-ssh key to Jenkins via the web UI: http://10.10.140.24:8080/credentials/store/system/domain/_/newCredentials
# SSH Username with private key
# ID: jenkins-ssh
# Username: icn.jenkins
# Private key: use the one Cheng sent over email.

# and this is the key for SSHing to the cluster by jenkins/bluval:
# put the private key where it can be accessed by jenkins [ideally a fresh one should be created at this point]
# this is the CLUSTER_SSH_KEY -> CLUSTER_SSH_KEY=/var/lib/jenkins/jenkins-rsa
ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa
# >> and also copy public key to onap and akraino gerrits! for the time being, until validation merges the patch and I don't have to checkout
cp /root/.ssh/id_rsa /var/lib/jenkins/jenkins-rsa
chown jenkins:jenkins /var/lib/jenkins/jenkins-rsa

# and here's the temporary part about having the right validation patch:
cd ~/ci-management
sed -i 's/ssh:\/\/akraino-jobbuilder@gerrit.akraino.org:29418/https:\/\/github.com\/igordcard/' jjb/defaults.yaml

pip install jenkins-job-builder

# or just $ jenkins-jobs test/update, if you logout and login again before
python2 -m jenkins_jobs test ci-management/jjb:icn/ci/jjb icn-master-verify
python2 -m jenkins_jobs update ci-management/jjb:icn/ci/jjb icn-master-verify
python2 -m jenkins_jobs test ci-management/jjb:icn/ci/jjb icn-bluval-daily-master
python2 -m jenkins_jobs update ci-management/jjb:icn/ci/jjb icn-bluval-daily-master

# install the Rebuilder plugin to easily rebuild a job with the same/similar parameters:
# Go to: http://10.10.140.24:8080/pluginManager/available and install "Rebuilder"

# and let jenkins call docker
usermod -aG docker jenkins

systemctl restart jenkins

# >> check kubespray-up.sh

pip3 install lftools # need to install as root


# Bluval Part

# kud installation will take care of the following:
#
# apt-get update
# apt-get install -y \
#     apt-transport-https \
#     ca-certificates \
#     curl \
#     gnupg-agent \
#     software-properties-common
# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
# apt-key fingerprint 0EBFCD88
# add-apt-repository \
#    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
#    $(lsb_release -cs) \
#    stable"
# apt-get update
# apt-get install -y \
#     docker-ce \
#     docker-ce-cli\
#     containerd.io

cd
mkdir results
git clone "https://gerrit.akraino.org/r/validation"
cd validation

cat << EOF | tee bluval/volumes.yaml
volumes:
    ssh_key_dir:
        local: '/root/.ssh'
        target: '/root/.ssh'
    kube_config_dir:
        local: '/root/.kube'
        target: '/root/.kube'
    custom_variables_file:
        local: '/root/validation/tests/variables.yaml'
        target: '/opt/akraino/validation/tests/variables.yaml'
    blueprint_dir:
        local: '/root/validation/bluval'
        target: '/opt/akraino/validation/bluval'
    results_dir:
        local: '/root/results'
        target: '/opt/akraino/results'
    openrc:
        local: '/root/openrc'
        target: '/root/openrc'
layers:
    common:
        - custom_variables_file
        - blueprint_dir
        - results_dir
    hardware:
        - ssh_key_dir
    os:
        - ssh_key_dir
    networking:
        - ssh_key_dir
    docker:
        - ssh_key_dir
    k8s:
        - ssh_key_dir
        - kube_config_dir
    k8s_networking:
        - ssh_key_dir
        - kube_config_dir
    openstack:
        - openrc
    sds:
    sdn:
    vim:
EOF

sed -i "s/172.28.17.206/localhost/" tests/variables.yaml
sed -i "s/cloudadmin/root/" tests/variables.yaml
sed -i "s/cloudpassword/s/" tests/variables.yaml
sed -i "s/: ssh_keyfile/: \/root\/.ssh\/id_rsa/" tests/variables.yaml

# or:
# git fetch "https://gerrit.akraino.org/r/validation" refs/changes/70/3370/1 && git checkout FETCH_HEAD
# git checkout -b 3370
cat << EOF | tee bluval/bluval-icn.yaml
blueprint:
    name: icn
    layers:
        - os
        - k8s
    os: &os
        -
            name: lynis
            what: lynis
            optional: "False"
        -
            name: vuls
            what: vuls
            optional: "False"

    k8s: &k8s
        -
            name: kube-hunter
            what: kube-hunter
        -
            name: conformance
            what: conformance
            optional: "False"
EOF

# allow OS tests to run in the same machine as bluval:
sed -i "s/docker run --rm/docker run --rm --net=host/" bluval/blucon.py

bluval/blucon.sh -l os icn
#python3 bluval/blucon.py -l os icn


# bluval-daily-master
# highly wip

# ssh-keygen -t rsa -N "" -f /root/jenkins-rsa
# chmod 644 /root/jenkins-rsa

#
# run conformance manually:
# kubectl apply -f /opt/akraino/validation/tests/k8s/conformance/sonobuoy.yaml 2>&
# kubectl get pod sonobuoy --namespace sonobuoy
# kubectl get pod sonobuoy --namespace sonobuoy 2>&1
# kubectl delete -f /opt/akraino/validation/tests/k8s/conformance${/}sonobuoy.yaml
# kubectl delete -f /opt/akraino/validation/tests/k8s/conformance/sonobuoy.yaml 2>&1
