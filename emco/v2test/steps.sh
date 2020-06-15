#!/bin/bash

# run as root

ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa

git clone https://github.com/onap/multicloud-k8s.git
pushd multicloud-k8s/kud/hosting_providers/vagrant
./setup.sh -p libvirt
popd
pushd multicloud-k8s/kud/hosting_providers/containerized
cp -R testing testing2
cd testing
sed -i "s/\"ubuntu18\"/\"cluster-101\"/" Vagrantfile
vagrant up
VAGRANT_IP_ADDR1=$(vagrant ssh-config | grep HostName | cut -f 4 -d " ")
ssh-copy-id -f -i ~/.ssh/id_rsa.pub -o "IdentityFile .vagrant/machines/default/libvirt/private_key" vagrant@$VAGRANT_IP_ADDR1
cd ../testing2
sed -i "s/\"ubuntu18\"/\"cluster-102\"/" Vagrantfile
vagrant up
VAGRANT_IP_ADDR2=$(vagrant ssh-config | grep HostName | cut -f 4 -d " ")
ssh-copy-id -f -i ~/.ssh/id_rsa.pub -o "IdentityFile .vagrant/machines/default/libvirt/private_key" vagrant@$VAGRANT_IP_ADDR2
popd
cd multicloud-k8s

# install kubernetes/docker using KUD AIO:
sed -i 's/localhost/$HOSTNAME/' kud/hosting_providers/baremetal/aio.sh
kud/hosting_providers/baremetal/aio.sh

# if proxy is needed:
# docker build  --rm \
# 	--build-arg http_proxy=${http_proxy} \
# 	--build-arg HTTP_PROXY=${HTTP_PROXY} \
# 	--build-arg https_proxy=${https_proxy} \
# 	--build-arg HTTPS_PROXY=${HTTPS_PROXY} \
# 	--build-arg no_proxy=${no_proxy} \
# 	--build-arg NO_PROXY=${NO_PROXY} \
#   --build-arg KUD_ENABLE_TESTS=true \
#   --build-arg KUD_PLUGIN_ENABLED=true \
# 	-t github.com/onap/multicloud-k8s:latest . -f kud/build/

docker build  --rm \
    --build-arg KUD_ENABLE_TESTS=true \
    --build-arg KUD_PLUGIN_ENABLED=true \
    -t github.com/onap/multicloud-k8s:latest . -f kud/build/Dockerfile

mkdir -p /opt/kud/multi-cluster/{cluster-101,cluster-102}

cat > /opt/kud/multi-cluster/cluster-101/hosts.ini <<EOF
[all]
c01 ansible_ssh_host=$VAGRANT_IP_ADDR1 ansible_ssh_port=22

[kube-master]
c01

[kube-node]
c01

[etcd]
c01

[ovn-central]
c01

[ovn-controller]
c01

[virtlet]
c01

[k8s-cluster:children]
kube-node
kube-master
EOF
cat > /opt/kud/multi-cluster/cluster-102/hosts.ini <<EOF
[all]
c01 ansible_ssh_host=$VAGRANT_IP_ADDR2 ansible_ssh_port=22

[kube-master]
c01

[kube-node]
c01

[etcd]
c01

[ovn-central]
c01

[ovn-controller]
c01

[virtlet]
c01

[k8s-cluster:children]
kube-node
kube-master
EOF

kubectl create secret generic ssh-key-secret --from-file=id_rsa=~/.ssh/id_rsa --from-file=id_rsa.pub=~/.ssh/id_rsa.pub
./installer.sh --install_pkg