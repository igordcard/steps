#!/bin/bash

# not meant as a script, meant as a copypad
# run as root

# for EMCO 21.06, ??? i.e. for K8s 1.19 and latest KUD deployment files
# also updated for Ubuntu 20.04 (20.12 script was for Ubuntu 18.04)

mk8sgit="https://github.com/onap/multicloud-k8s.git"
emcogit="https://gitlab.com/project-emco/core/emco-base.git"

MK8S_REMOTE="$mk8sgit"
git clone $MK8S_REMOTE
MK8S_DIR=~/multicloud-k8s

# recommendation, add the following to .bashrc:
export MK8S_DIR=~/multicloud-k8s # last commit ID tested: ac7751ec
export EMCO_DIR=~/emco-base

apt-get install build-essential qemu-kvm libvirt-daemon-system libvirt-dev python3 python-is-python3 -y
curl -O https://releases.hashicorp.com/vagrant/2.2.14/vagrant_2.2.14_x86_64.deb
adduser $USER libvirt
apt-get install ./vagrant_2.2.14_x86_64.deb
CONFIGURE_ARGS="with-libvirt-include=/usr/include/libvirt with-libvirt-lib=/usr/lib" vagrant plugin install vagrant-libvirt

# template sample vagrant clusters:
cd $MK8S_DIR/kud/hosting_providers/containerized/
cp -R testing cluster01
cp -R testing cluster02
cp -R testing cluster03

# prepare the 1st vagrant VM cluster:
cd $MK8S_DIR/kud/hosting_providers/containerized/cluster01
sed -i "s/\"ubuntu18\"/\"cluster01\"/" Vagrantfile
sed -i "s/memory = 32768/memory = 8192/" Vagrantfile
sed -i "s/cpus = 16/cpus = 2/" Vagrantfile
sed -i "s/size = 400/size = 20/" Vagrantfile
vagrant up

export VAGRANT_IP_ADDR1=$(vagrant ssh-config | grep HostName | cut -f 4 -d " ")
sed -i '/VAGRANT_IP_ADDR1/d' ~/.bashrc
echo "export VAGRANT_IP_ADDR1=$VAGRANT_IP_ADDR1" >> ~/.bashrc

ssh-copy-id -f -i ~/.ssh/id_rsa.pub -o "IdentityFile .vagrant/machines/default/libvirt/private_key" -o StrictHostKeyChecking=no vagrant@$VAGRANT_IP_ADDR1
ssh vagrant@$VAGRANT_IP_ADDR1 -t "sudo su -c 'mkdir /root/.ssh; cp /home/vagrant/.ssh/authorized_keys /root/.ssh/'"

# SEE(INSIDE-VAGRANT)

# prepare the 2nd vagrant VM cluster:
cd $MK8S_DIR/kud/hosting_providers/containerized/cluster02
sed -i "s/\"ubuntu18\"/\"cluster02\"/" Vagrantfile
sed -i "s/memory = 32768/memory = 8192/" Vagrantfile
sed -i "s/cpus = 16/cpus = 2/" Vagrantfile
sed -i "s/size = 400/size = 20/" Vagrantfile
vagrant up

export VAGRANT_IP_ADDR2=$(vagrant ssh-config | grep HostName | cut -f 4 -d " ")
sed -i '/VAGRANT_IP_ADDR2/d' ~/.bashrc
echo "export VAGRANT_IP_ADDR2=$VAGRANT_IP_ADDR2" >> ~/.bashrc

ssh-copy-id -f -i ~/.ssh/id_rsa.pub -o "IdentityFile .vagrant/machines/default/libvirt/private_key" -o StrictHostKeyChecking=no vagrant@$VAGRANT_IP_ADDR2
ssh vagrant@$VAGRANT_IP_ADDR2 -t "sudo su -c 'mkdir /root/.ssh; cp /home/vagrant/.ssh/authorized_keys /root/.ssh/'"

# prepare the 3rd vagrant VM cluster:
cd $MK8S_DIR/kud/hosting_providers/containerized/cluster03
sed -i "s/\"ubuntu18\"/\"cluster03\"/" Vagrantfile
sed -i "s/memory = 32768/memory = 8192/" Vagrantfile
sed -i "s/cpus = 16/cpus = 2/" Vagrantfile
sed -i "s/size = 400/size = 20/" Vagrantfile
vagrant up

export VAGRANT_IP_ADDR3=$(vagrant ssh-config | grep HostName | cut -f 4 -d " ")
sed -i '/VAGRANT_IP_ADDR3/d' ~/.bashrc
echo "export VAGRANT_IP_ADDR3=$VAGRANT_IP_ADDR3" >> ~/.bashrc

ssh-copy-id -f -i ~/.ssh/id_rsa.pub -o "IdentityFile .vagrant/machines/default/libvirt/private_key" -o StrictHostKeyChecking=no vagrant@$VAGRANT_IP_ADDR3
ssh vagrant@$VAGRANT_IP_ADDR3 -t "sudo su -c 'mkdir /root/.ssh; cp /home/vagrant/.ssh/authorized_keys /root/.ssh/'"


# SEE(INSIDE-VAGRANT)

#####

# bring back deployment after rebooting

cd $MK8S_DIR/kud/hosting_providers/containerized/cluster01
vagrant up
cd $MK8S_DIR/kud/hosting_providers/containerized/cluster02
vagrant up
cd $MK8S_DIR/kud/hosting_providers/containerized/cluster03
vagrant up

#####

# if vars lost:
cd
cd $MK8S_DIR/kud/hosting_providers/containerized/cluster01
export VAGRANT_IP_ADDR1=$(vagrant ssh-config | grep HostName | cut -f 4 -d " ")
cd $MK8S_DIR/kud/hosting_providers/containerized/cluster02
export VAGRANT_IP_ADDR2=$(vagrant ssh-config | grep HostName | cut -f 4 -d " ")


# ===========================
# inside each of the clusters
# REF(INSIDE-VAGRANT)

ssh root@$VAGRANT_IP_ADDR1

ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa

MK8S_REMOTE="$mk8sgit"
git clone $MK8S_REMOTE
MK8S_DIR=~/multicloud-k8s
cd $MK8S_DIR

# install kubernetes/docker using KUD AIO (global cluster)

# fix hostnames to localhost:
sed -i 's/^localhost/$HOSTNAME/' kud/hosting_providers/baremetal/aio.sh

# >> disable addons:
vim kud/hosting_providers/vagrant/installer.sh
# comment the following lines near the end of the file:

#install_addons
#if ${KUD_PLUGIN_ENABLED:-false}; then
#    install_plugin
#fi

# deploy KUD
kud/hosting_providers/baremetal/aio.sh

exit

#####

# repeat the above but for:
ssh root@$VAGRANT_IP_ADDR2
# SEE(INSIDE-VAGRANT)


# ===========================
# back out to the main host
# REF(INSTALL-EMCO-DEPS)

apt-get install -y docker-compose mongodb-clients etcd-client build-essential

source $MK8S_DIR/deployments/_functions.sh
cd $MK8S_DIR/deployments

# install MongoDB
stop_all
start_mongo

cd

# install etcd
cat >> docker-compose.yml << \EOF
version: '2'
services:
  etcd:
    image: bitnami/etcd:3
    environment:
      - ALLOW_NONE_AUTHENTICATION=yes
      - HTTP_PROXY=${HTTP_PROXY}
      - HTTPS_PROXY=${HTTPS_PROXY}
      - NO_PROXY=${NO_PROXY}
    volumes:
      - etcd_data:/bitnami/etcd
volumes:
  etcd_data:
    driver: local
EOF
docker-compose up -d etcd

export MONGO_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -aqf "name=mongo"))
export ETCD_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -aqf "name=etcd"))

# as an extra add the vars to bashrc so they're always in the env
sed -i '/MONGO_IP/d' ~/.bashrc
echo "export MONGO_IP=$MONGO_IP" >> ~/.bashrc
sed -i '/ETCD_IP/d' ~/.bashrc
echo "export ETCD_IP=$ETCD_IP" >> ~/.bashrc

# when rebooting the host, restart the docker containers:
docker start deployments_mongo_1
docker start root_etcd_1

# ===========================
# install Go
# REF(INSTALL-GO)
cd
export GO_VERSION="1.14.14"
#export GO_VERSION="1.15.7"
curl -O https://storage.googleapis.com/golang/go$GO_VERSION.linux-amd64.tar.gz
tar -xvf go$GO_VERSION.linux-amd64.tar.gz
mv go /usr/local
cat >> ~/.profile <<\EOF
export GOPATH=$HOME/work
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
EOF
source ~/.profile


# ===========================
# compile and configure the EMCO services
# REF(CONFIGURE-EMCO)

EMCO_REMOTE="$emcogit"
EMCO_DIR=~/emco-base
git clone $EMCO_REMOTE $EMCO_DIR

# you'll need to setup the EMCO dependencies properly first:
# SEE(INSTALL-EMCO-DEPS)

# compile all services
cd $EMCO_DIR
make compile-container

# orchestrator's config.json:
mkdir -p $EMCO_DIR/bin/orchestrator
cd $EMCO_DIR/bin/orchestrator
cat > config.json << EOF
{
    "ca-file": "ca.cert",
    "server-cert": "server.cert",
    "server-key": "server.key",
    "password": "",
    "database-ip": "$MONGO_IP",
    "database-type": "mongo",
    "plugin-dir": "plugins",
    "etcd-ip": "$ETCD_IP",
    "etcd-cert": "",
    "etcd-key": "",
    "etcd-ca-file": "",
    "service-port": "9015",
    "log-level": "trace"
}
EOF

# clm's config.clm:
mkdir -p $EMCO_DIR/bin/clm
cd $EMCO_DIR/bin/clm
cat > config.json << EOF
{
    "database-type": "mongo",
    "database-ip": "$MONGO_IP",
    "etcd-ip": "$ETCD_IP",
    "service-port": "9061",
    "log-level": "trace"
}
EOF

# rsync's config.json:
mkdir -p $EMCO_DIR/bin/rsync
cd $EMCO_DIR/bin/rsync
cat > config.json << EOF
{
    "database-type": "mongo",
    "database-ip": "$MONGO_IP",
    "etcd-ip": "$ETCD_IP",
    "service-port": "9031",
    "log-level": "trace"
}
EOF

# ncm's config.json:
mkdir -p $EMCO_DIR/bin/ncm
cd $EMCO_DIR/bin/ncm
cat > config.json << EOF
{
    "database-type": "mongo",
    "database-ip": "$MONGO_IP",
    "etcd-ip": "$ETCD_IP",
    "service-port": "9081",
    "log-level": "trace"
}
EOF

# dcm's config.json:
mkdir -p $EMCO_DIR/bin/dcm
cd $EMCO_DIR/bin/dcm
#generate_k8sconfig #optional, for k8s deployment
cat > config.json << EOF
{
    "database-ip": "$MONGO_IP",
    "database-type": "mongo",
    "plugin-dir": "plugins",
    "service-port": "9077",
    "ca-file": "ca.cert",
    "server-cert": "server.cert",
    "server-key": "server.key",
    "password": "",
    "etcd-ip": "$ETCD_IP",
    "etcd-cert": "",
    "etcd-key": "",
    "etcd-ca-file": "",
    "log-level": "trace"
}
EOF

# ovnaction's config.json:
mkdir -p $EMCO_DIR/bin/ovnaction
cd $EMCO_DIR/bin/ovnaction
cat > config.json << EOF
{
    "database-type": "mongo",
    "database-ip": "$MONGO_IP",
    "etcd-ip": "$ETCD_IP",
    "service-port": "9051",
    "log-level": "trace"
}
EOF

# dtc's config.json:
mkdir -p $EMCO_DIR/bin/dtc
cd $EMCO_DIR/bin/dtc
cat > config.json << EOF
{
    "database-type": "mongo",
    "database-ip": "$MONGO_IP",
    "etcd-ip": "$ETCD_IP",
    "service-port": "9018",
    "log-level": "trace"
}
EOF

# genericactioncontroller's config.json:
mkdir -p $EMCO_DIR/bin/genericactioncontroller
cd $EMCO_DIR/bin/genericactioncontroller
cat > config.json << EOF
{
    "database-type": "mongo",
    "database-ip": "$MONGO_IP",
    "etcd-ip": "$ETCD_IP",
    "service-port": "9020",
    "log-level": "trace"
}
EOF

# ===========================
# set json-schemas for each service
# REF(JSON-SCHEMAS)
EMCO_DIR=~/emco-base
cd $EMCO_DIR/bin/orchestrator
cp -R $EMCO_DIR/src/orchestrator/json-schemas .
cd $EMCO_DIR/bin/clm
cp -R $EMCO_DIR/src/clm/json-schemas .
cd $EMCO_DIR/bin/rsync
cp -R $EMCO_DIR/src/rsync/json-schemas .
cd $EMCO_DIR/bin/ncm
cp -R $EMCO_DIR/src/ncm/json-schemas .
cd $EMCO_DIR/bin/dcm
cp -R $EMCO_DIR/src/dcm/json-schemas .
cd $EMCO_DIR/bin/ovnaction
cp -R $EMCO_DIR/src/ovnaction/json-schemas .
cd $EMCO_DIR/bin/dtc
cp -R $EMCO_DIR/src/dtc/json-schemas .
cd $EMCO_DIR/bin/genericactioncontroller
cp -R $EMCO_DIR/src/genericactioncontroller/json-schemas .

# ===========================
# set ref-schemas for each service
# REF(REF-SCHEMAS)
EMCO_DIR=~/emco-base
cd $EMCO_DIR/bin/orchestrator
cp -r $EMCO_DIR/src/orchestrator/ref-schemas $EMCO_DIR/bin/orchestrator/ref-schemas/.

# ===========================
# the monitor service also needs to be running on each cluster
# commands simplified, some may be missing
# REF(DEPLOY-MONITOR)

ssh root@$VAGRANT_IP_ADDR1

git clone $emcogit emco-base
cd emco-base/src/monitor/deploy

./monitor-deploy.sh

# do the same for other clusters

# To re-deploy monitor and related resources suchs as the ResourceBundleState CRD:
cd emco-base
git pull
cd src/monitor/deploy
./monitor-cleanup.sh
kubectl delete crd --all # CRD may be dangling
sleep 15
./monitor-deploy.sh


# ===========================
# run the EMCO services in tmux
# REF(RUN-EMCO)

tmux

# do the following in separate windows
EMCO_DIR=~/emco-base
cd $EMCO_DIR/bin/orchestrator
killall orchestrator
./orchestrator >> log.txt 2>&1

EMCO_DIR=~/emco-base
cd $EMCO_DIR/bin/rsync
killall rsync
./rsync >> log.txt 2>&1

EMCO_DIR=~/emco-base
cd $EMCO_DIR/bin/clm
killall clm
./clm >> log.txt 2>&1

EMCO_DIR=~/emco-base
cd $EMCO_DIR/bin/dcm
killall dcm
./dcm >> log.txt 2>&1

EMCO_DIR=~/emco-base
cd $EMCO_DIR/bin/ncm
killall ncm
./ncm >> log.txt 2>&1

EMCO_DIR=~/emco-base
cd $EMCO_DIR/bin/ovnaction
killall ovnaction
./ovnaction >> log.txt 2>&1

EMCO_DIR=~/emco-base
cd $EMCO_DIR/bin/dtc
killall dtc
./dtc >> log.txt 2>&1

EMCO_DIR=~/emco-base
killall genericactioncontroller
cd $EMCO_DIR/bin/genericactioncontroller
./genericactioncontroller >> log.txt 2>&1

# alternatively launch them all in the background and kill them later
EMCO_DIR=~/emco-base
cd $EMCO_DIR/bin/orchestrator
killall orchestrator
./orchestrator >> log.txt 2>&1 &
cd $EMCO_DIR/bin/rsync
killall rsync
./rsync >> log.txt 2>&1 &
cd $EMCO_DIR/bin/clm
killall clm
./clm >> log.txt 2>&1 &
cd $EMCO_DIR/bin/dcm
killall dcm
./dcm >> log.txt 2>&1 &
cd $EMCO_DIR/bin/ncm
killall ncm
./ncm >> log.txt 2>&1 &
cd $EMCO_DIR/bin/ovnaction
killall ovnaction
./ovnaction >> log.txt 2>&1 &
cd $EMCO_DIR/bin/dtc
killall dtc
./dtc >> log.txt 2>&1 &
cd $EMCO_DIR/bin/genericactioncontroller
killall genericactioncontroller
./genericactioncontroller >> log.txt 2>&1 &



# ===========================
# some useful commands while developing
# REF(DEV-EMCO)

# compile all services
EMCO_DIR=~/emco-base
cd $EMCO_DIR/src/orchestrator
make
cd $EMCO_DIR/src/rsync
make
cd $EMCO_DIR/src/clm
make
cd $EMCO_DIR/src/dcm
make
cd $EMCO_DIR/src/ncm
make
cd $EMCO_DIR/src/ovnaction
make
cd $EMCO_DIR/src/dtc
make
cd $EMCO_DIR/src/monitor
make
cd $EMCO_DIR/src/genericactioncontroller
make
cd $EMCO_DIR/src/tools/emcoctl
make
cd $EMCO_DIR

# git add all source
git add $EMCO_DIR/src

# restoring all go.mods to a particular version
cd $EMCO_DIR/src
rm */go.sum
commit_id=COMMIT_ID
git checkout $commit_id -- clm/go.mod
git checkout $commit_id -- dcm/go.mod
git checkout $commit_id -- dtc/go.mod
git checkout $commit_id -- monitor/go.mod
git checkout $commit_id -- ncm/go.mod
git checkout $commit_id -- orchestrator/go.mod
git checkout $commit_id -- ovnaction/go.mod
git checkout $commit_id -- rsync/go.mod

# generating protobuf files for Go
apt-get install protobuf-compiler
apt-get install golang-goprotobuf-dev
protoc --go_out=. cloudready.proto

# prepare typical files needed by emcoctl
scp root@$VAGRANT_IP_ADDR1:.kube/config ~/c01.config
scp root@$VAGRANT_IP_ADDR2:.kube/config ~/c02.config
scp root@$VAGRANT_IP_ADDR3:.kube/config ~/c03.config

# prepare tarballs necessary by example DIGs (/opt/csar stuff)
mkdir -p /opt/csar
cd /opt/csar
tar -czf collectd.tar.gz -C $EMCO_DIR/kud/tests/vnfs/comp-app/collection/app1/helm .
tar -czf collectd_profile.tar.gz -C $EMCO_DIR/kud/tests/vnfs/comp-app/collection/app1/profile .
tar -czf prometheus-operator.tar.gz -C $EMCO_DIR/kud/tests/vnfs/comp-app/collection/app2/helm .
tar -czf prometheus-operator_profile.tar.gz -C $EMCO_DIR/kud/tests/vnfs/comp-app/collection/app2/profile .

# emcoctl testing commands
EMCO_DIR=~/emco-base
alias emcoctl='$EMCO_DIR/bin/emcoctl/emcoctl'
emcoctl --config emco-cfg.yaml -v values2.yaml -f step1.yaml apply
emcoctl --config emco-cfg.yaml -v values2.yaml -f step2.yaml apply
emcoctl --config emco-cfg.yaml -v values2.yaml -f step1.yaml delete
emcoctl --config emco-cfg.yaml -v values2.yaml -f step2.yaml delete


# see emco-helpers.sh for additional useful commands, including creating an EMCO project
# see extra-cmds.sh for other debugging commands

# ===========================
# forward ports locally to make API interaction easy
# REF(LOCAL-FORWARD)

dev_ip=127.0.0.1
jump_ip=192.168.1.100
jump_port=22

# these are just functions that set specific IP addresses to the vars above:
internet_vars
intranet_vars

# orchestrator
ssh -fNT -L 9015:$dev_ip:9015 root@$jump_ip -p $jump_port
# clm
ssh -fNT -L 9061:$dev_ip:9061 root@$jump_ip -p $jump_port
# dcm
ssh -fNT -L 9077:$dev_ip:9077 root@$jump_ip -p $jump_port
# ncm
ssh -fNT -L 9081:$dev_ip:9081 root@$jump_ip -p $jump_port
# ovnaction
ssh -fNT -L 9051:$dev_ip:9051 root@$jump_ip -p $jump_port
# dtc
ssh -fNT -L 9018:$dev_ip:9018 root@$jump_ip -p $jump_port
# ovnaction (grpc)
ssh -fNT -L 9032:$dev_ip:9032 root@$jump_ip -p $jump_port #grpc
# rsync (grpc)
ssh -fNT -L 9031:$dev_ip:9031 root@$jump_ip -p $jump_port #grpc

# mongodb
#ssh -fNT -L 27017:172.19.0.2:27017 root@$jump_ip -p $jump_port #mongo
ssh -fNT -L 27017:172.18.0.2:27017 root@$jump_ip -p $jump_port #mongo

# etcd
ssh -fNT -L 2379:172.19.0.2:2379 root@$jump_ip -p $jump_port #etcd

# just a function that forwards all services from above:
forward_all

# ===========================
# REF(RUN-EXAMPLES)
EMCO_DIR=~/emco-base
cd $EMCO_DIR/src/tools/emcoctl/examples/l1/2clusters
emcoctl --config ../../emco-cfg.yaml apply -f 1-logical-cloud-prerequisites.yaml -v ../values.yaml
emcoctl --config ../../emco-cfg.yaml apply -f 2-logical-cloud-instantiate.yaml -v ../values.yaml
