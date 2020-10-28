#!/bin/bash

# 1. run deps-up.sh

# 2. continue

WORKDIR=~/multicloud-k8s
sed -i '/WORKDIR/d' ~/.bashrc
echo "export WORKDIR=$WORKDIR" >> ~/.bashrc

cd $WORKDIR/src/orchestrator && make all
cd $WORKDIR/src/ncm && make all
cd $WORKDIR/src/rsync && make all
cd $WORKDIR/src/ovnaction && make all
cd $WORKDIR/src/clm && make all
cd $WORKDIR/src/dcm && make all

export ETCD_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -aqf "name=etcd"))
export DATABASE_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -aqf "name=mongo"))

# see dcm-up.sh for how to prepare the services' config.jsons

# easily bring up emco for dev
sed -i '/emco/d' ~/.bashrc
cat >> ~/.bashrc << EOF
alias emco='tmux new-session -s emco "tmux source-file ~/.tmux.conf"'
EOF
cat > ~/.tmux.conf << EOF
new
neww
rename-window mco
send-keys 'cd $WORKDIR/src/orchestrator && ./orchestrator' Enter
splitw -h
send-keys 'cd $WORKDIR/src/clm && ./clm' Enter
splitw -h
send-keys 'cd $WORKDIR/src/rsync && ./rsync' Enter
select-layout even-horizontal
neww
rename-window dcm
send-keys 'cd $WORKDIR/src/dcm && ./dcm' Enter
#splitw -v
EOF

# at this point, copy .kube/config from intended cluster and test
# connectivity with kubectl before adding the cluster to clm

# run EMCO on tmux:
emco

# Create test-project Project before using any API
cd $WORKDIR/src/orchestrator
cat > create-project.json << EOF
{"metadata": {"name": "test-project"}}
EOF
curl --header "Content-Type: application/json" --request POST --data @create-project.json http://127.0.0.1:9015/v2/projects
