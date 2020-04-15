#!/bin/bash

# requirements:
# - host that doesn't need proxy configs anymore

# Jenkins Part

sudo apt-get install -y python
wget https://bootstrap.pypa.io/get-pip.py
sudo python2 get-pip.py
git clone "https://gerrit.akraino.org/r/icn"
cd icn/ci
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

sed -i "s/\/opt\/akraino/\/home\/stack/" bluval/volumes.yaml
sed -i "s/\/root\//\/home\/stack\//" bluval/volumes.yaml

sed -i "s/172.28.17.206/localhost/" tests/variables.yaml
sed -i "s/cloudadmin/stack/" tests/variables.yaml
sed -i "s/\/root\//\/home\/stack\//" tests/variables.yaml

cat << EOF | tee bluval/bluval-rec.yaml
blueprint:
    name: rec
    layers:
        - k8s
    k8s: &k8s
        -
            name: kube-hunter
            what: kube-hunter
EOF

sudo bluval/blucon.sh -l k8s rec