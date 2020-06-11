git clone https://github.com/onap/multicloud-k8s.git
pushd multicloud-k8s/kud/hosting_providers/vagrant
sudo ./setup.sh -p libvirt
popd
pushd multicloud-k8s/kud/hosting_providers/containerized/testing
sudo vagrant up
VAGRANT_IP_ADDRESS=$(sudo vagrant ssh-config | grep HostName | cut -f 4 -d " ")
popd
cd multicloud-k8s

# install docker-ce manually using install-docker.sh
# #######

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

sudo docker build  --rm \
    --build-arg KUD_ENABLE_TESTS=true \
    --build-arg KUD_PLUGIN_ENABLED=true \
    -t github.com/onap/multicloud-k8s:latest . -f kud/build/Dockerfile

sudo mkdir -p /opt/kud/multi-cluster/{cluster-101,cluster-102}

sudo su -c "cat > /opt/kud/multi-cluster/cluster-101/hosts.ini <<EOF
[all]
c01 ansible_ssh_host=$VAGRANT_IP_ADDRESS ansible_ssh_port=22

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
EOF"