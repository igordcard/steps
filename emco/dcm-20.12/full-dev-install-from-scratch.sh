#!/bin/bash

# not meant as a script, meant as a copypad
# run as root

MK8S_REMOTE="https://github.com/onap/multicloud-k8s.git"
git clone $MK8S_REMOTE
MK8S_DIR=~/multicloud-k8s

apt-get install vagrant -y
$MK8S_DIR/kud/hosting_providers/vagrant/setup.sh -p libvirt

# template sample vagrant clusters:
cd $MK8S_DIR/kud/hosting_providers/containerized/
cp -R testing cluster01
cp -R testing cluster02
cp -R testing cluster03

# prepare the 1st vagrant VM cluster:
cd $MK8S_DIR/kud/hosting_providers/containerized/cluster01
sed -i "s/\"ubuntu18\"/\"cluster01\"/" Vagrantfile
sed -i "s/memory = 32768/memory = 10248/" Vagrantfile
sed -i "s/cpus = 16/cpus = 2/" Vagrantfile
sed -i "s/size = 400/size = 30/" Vagrantfile
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
sed -i "s/memory = 32768/memory = 10248/" Vagrantfile
sed -i "s/cpus = 16/cpus = 2/" Vagrantfile
sed -i "s/size = 400/size = 30/" Vagrantfile
vagrant up

export VAGRANT_IP_ADDR2=$(vagrant ssh-config | grep HostName | cut -f 4 -d " ")
sed -i '/VAGRANT_IP_ADDR2/d' ~/.bashrc
echo "export VAGRANT_IP_ADDR2=$VAGRANT_IP_ADDR2" >> ~/.bashrc
ssh-copy-id -f -i ~/.ssh/id_rsa.pub -o "IdentityFile .vagrant/machines/default/libvirt/private_key" -o StrictHostKeyChecking=no vagrant@$VAGRANT_IP_ADDR2
ssh vagrant@$VAGRANT_IP_ADDR2 -t "sudo su -c 'mkdir /root/.ssh; cp /home/vagrant/.ssh/authorized_keys /root/.ssh/'"

# SEE(INSIDE-VAGRANT)

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

MK8S_REMOTE="https://github.com/onap/multicloud-k8s.git"
git clone $MK8S_REMOTE
MK8S_DIR=~/multicloud-k8s

cd $MK8S_DIR

# install kubernetes/docker using KUD AIO (global cluster):
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


# ===========================
# install Go
# REF(INSTALL-GO)
cd
export GO_VERSION="1.14.12"
#export GO_VERSION="1.15.5"
curl -O https://storage.googleapis.com/golang/go$GO_VERSION.linux-amd64.tar.gz
tar -xvf go$GO_VERSION.linux-amd64.tar.gz
sudo mv go /usr/local
cat >> ~/.profile <<\EOF
export GOPATH=$HOME/work
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
EOF
source ~/.profile


# ===========================
# compile and configure the EMCO services
# REF(CONFIGURE-EMCO)

EMCO_REMOTE="https://github.com/onap/multicloud-k8s.git"
git clone $EMCO_REMOTE
EMCO_DIR=~/multicloud-k8s

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
    "service-port": "9041",
    "log-level": "trace"
}
EOF

mkdir -p $EMCO_DIR/bin/dcm
cd $EMCO_DIR/bin/dcm
#generate_k8sconfig
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


# ===========================
# the monitor service also needs to be running on each cluster
# commands simplified, some may be missing
# REF(DEPLOY-MONITOR)
ssh root@$VAGRANT_IP_ADDR1
git clone $EMCO_REMOTE
cd $EMCO_DIR/src/monitor/deploy
./monitor-deploy.sh


# ===========================
# run the EMCO services in tmux
# REF(RUN-EMCO)

tmux
# do the following in separate windows
EMCO_DIR=~/multicloud-k8s
cd $EMCO_DIR/bin/clm
./clm >> log.txt 2>&1
cd $EMCO_DIR/bin/dcm
./dcm >> log.txt 2>&1
cd $EMCO_DIR/bin/ncm
./ncm >> log.txt 2>&1
cd $EMCO_DIR/bin/orchestrator
./orchestrator >> log.txt 2>&1
cd $EMCO_DIR/bin/ovnaction
./ovnaction >> log.txt 2>&1
cd $EMCO_DIR/bin/rsync
./rsync >> log.txt 2>&1


# ===========================
# some useful commands while developing
# REF(DEV-EMCO)

# compile all services
EMCO_DIR=~/EMCO
cd $EMCO_DIR/src/orchestrator
go mod vendor && make
cd $EMCO_DIR/src/rsync
go mod vendor && make
cd $EMCO_DIR/src/clm
go mod vendor && make
cd $EMCO_DIR/src/dcm
go mod vendor && make
cd $EMCO_DIR/src/ncm
go mod vendor && make
cd $EMCO_DIR/src/ovnaction
go mod vendor && make
cd $EMCO_DIR/src/monitor
go mod vendor && make
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

# see emco-helpers.sh for additional useful commands, including creating an EMCO project
# see extra-cmds.sh for other debugging commands

# ===========================
# forward ports locally to make API interaction easy
# REF(LOCAL-FORWARD)

dev_ip=127.0.0.1
jump_ip=192.168.1.100
jump_port=22

# these are just functions that set specific IP addresses to the vars above:
set_internet_vars
set_intranet_vars

# orchestrator
ssh -fNT -L 9015:$dev_ip:9015 root@$jump_ip -p $jump_port
# rsync
ssh -fNT -L 9031:$dev_ip:9031 root@$jump_ip -p $jump_port #grpc
# ncm
ssh -fNT -L 9081:$dev_ip:9081 root@$jump_ip -p $jump_port
# ovnaction
ssh -fNT -L 9051:$dev_ip:9051 root@$jump_ip -p $jump_port
# ovnaction (grpc)
ssh -fNT -L 9032:$dev_ip:9032 root@$jump_ip -p $jump_port #grpc
# clm
ssh -fNT -L 9061:$dev_ip:9061 root@$jump_ip -p $jump_port
# dcm
ssh -fNT -L 9077:$dev_ip:9077 root@$jump_ip -p $jump_port

# just a functions that forwards all services from above:
forward_all