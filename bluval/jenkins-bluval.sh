#!/bin/bash

# requirements:
# - host that doesn't need proxy configs anymore
# - use root user

# Jenkins and Kubernetes Part

apt-get install -y python build-essential python-bashate git-review # dependencies for icn job
wget https://bootstrap.pypa.io/get-pip.py
python2 get-pip.py
git clone "https://gerrit.akraino.org/r/icn"

# prep k8s
# only do this 1 machine -> the master
#cd icn
#make kud_bm_deploy_mini
# 1.16 instead:
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


# temporary fix for kubeadm download error that will happen
#mv /tmp/releases/kubeadm /tmp/releases/kubeadm-v1.16.9-amd64
# run again
#./aio.sh


cd ci
sed -i "s/2.192/\"2.230\"/" vars.yaml
./install_ansible.sh
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

pip install jenkins-job-builder

# or just $ jenkins-jobs test/update, if you logout and login again before
python2 -m jenkins_jobs test ci-management/jjb:icn/ci/jjb icn-master-verify
python2 -m jenkins_jobs update ci-management/jjb:icn/ci/jjb icn-master-verify


# Bluval Part

apt-get update
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get update
apt-get install -y \
    docker-ce \
    docker-ce-cli\
    containerd.io

cd
mkdir results
ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa
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
    name: rec
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

bluval/blucon.sh -l os icn # first time
#python3 bluval/blucon.py -l os icn # sufficient in subsequent times


# bluval-daily-master
# highly wip

ssh-keygen -t rsa -N "" -f /root/jenkins-rsa
chmod 644 /root/jenkins-rsa

usermod -aG docker jenkins
usermod -aG jenkins root # sometimes useful to cd into stuff

pip3 install lftools # need to install as root

#
# run conformance manually:
# kubectl apply -f /opt/akraino/validation/tests/k8s/conformance/sonobuoy.yaml 2>&
# kubectl get pod sonobuoy --namespace sonobuoy
# kubectl get pod sonobuoy --namespace sonobuoy 2>&1
# kubectl delete -f /opt/akraino/validation/tests/k8s/conformance${/}sonobuoy.yaml
# kubectl delete -f /opt/akraino/validation/tests/k8s/conformance/sonobuoy.yaml 2>&1
