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

cat > $WORKDIR/src/orchestrator/config.json << EOF
{
    "database-type": "mongo",
    "database-ip": "$DATABASE_IP",
    "etcd-ip": "$ETCD_IP",
    "service-port": "9015"
}
EOF
cat > $WORKDIR/src/ncm/config.json << EOF
{
    "database-type": "mongo",
    "database-ip": "$DATABASE_IP",
    "etcd-ip": "$ETCD_IP",
    "service-port": "9031"
}
EOF
cat > $WORKDIR/src/rsync/config.json << EOF
{
    "database-type": "mongo",
    "database-ip": "$DATABASE_IP",
    "etcd-ip": "$ETCD_IP",
    "service-port": "9017"
}
EOF
cat > $WORKDIR/src/ovnaction/config.json << EOF
{
    "database-type": "mongo",
    "database-ip": "$DATABASE_IP",
    "etcd-ip": "$ETCD_IP",
    "service-port": "9051"
}
EOF
cat > $WORKDIR/src/clm/config.json << EOF
{
    "database-type": "mongo",
    "database-ip": "$DATABASE_IP",
    "etcd-ip": "$ETCD_IP",
    "service-port": "9061"
}
EOF
cat > $WORKDIR/src/dcm/config.json << EOF
{
    "database-ip": "$DATABASE_IP",
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
    "etcd-ca-file": ""
}
EOF

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
neww
rename-window dcm
send-keys 'cd $WORKDIR/src/dcm && ./dcm' Enter
#splitw -v
EOF