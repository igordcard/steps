#!/bin/bash

# requirements:
# - host that doesn't need proxy configs anymore

# Jenkins Part

sudo apt-get install -y python
sudo apt-get install -y python-bashate # dependencies for icn job
wget https://bootstrap.pypa.io/get-pip.py
sudo python2 get-pip.py
git clone "https://gerrit.akraino.org/r/icn"

# prep k8s
cd icn
sudo su # important
make kud_bm_deploy_mini

cd ci
sed -i "s/2.192/\"2.230\"/" vars.yaml
sudo ./install_ansible.sh
sudo ansible-playbook site_jenkins.yaml --extra-vars "@vars.yaml" -vvv

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

sudo apt-get update
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get update
sudo apt-get install -y \
    docker-ce \
    docker-ce-cli\
    containerd.io

cd
mkdir results
ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa
git clone "https://gerrit.akraino.org/r/validation"
cd validation

# allow OS tests to run in the same machine as bluval:
sed -i "s/docker run --rm/docker run --rm --net=host/" bluval/blucon.py

sudo cp -R /root/.kube /home/stack/
sudo chown -R stack:stack /root/.kube /home/stack/

cat << EOF | tee bluval/volumes.yaml
volumes:
    ssh_key_dir:
        local: '/home/stack/.ssh'
        target: '/root/.ssh'
    kube_config_dir:
        local: '/home/stack/.kube'
        target: '/root/.kube'
    custom_variables_file:
        local: '/home/stack/validation/tests/variables.yaml'
        target: '/opt/akraino/validation/tests/variables.yaml'
    blueprint_dir:
        local: '/home/stack/validation/bluval'
        target: '/opt/akraino/validation/bluval'
    results_dir:
        local: '/home/stack/results'
        target: '/opt/akraino/results'
    openrc:
        local: '/home/stack/openrc'
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
sed -i "s/cloudadmin/stack/" tests/variables.yaml
sed -i "s/\/root\//\/home\/stack\//" tests/variables.yaml

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

sudo bluval/blucon.sh -l k8s icn


# bluval-daily-master
# highly wip

ssh-keygen -t rsa -N "" -f /home/stack/jenkins-rsa
chmod 644 /home/stack/jenkins-rsa

sudo usermod -aG docker jenkins
sudo usermod -aG jenkins stack # sometimes useful to cd into stuff

sudo su -c "pip3 install lftools" # need to install as root

#
# run conformance manually:
# kubectl apply -f /opt/akraino/validation/tests/k8s/conformance/sonobuoy.yaml 2>&
# kubectl get pod sonobuoy --namespace sonobuoy
# kubectl get pod sonobuoy --namespace sonobuoy 2>&1
# kubectl delete -f /opt/akraino/validation/tests/k8s/conformance${/}sonobuoy.yaml
# kubectl delete -f /opt/akraino/validation/tests/k8s/conformance/sonobuoy.yaml 2>&1