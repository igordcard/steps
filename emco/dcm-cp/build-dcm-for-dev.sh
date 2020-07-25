#!/bin/bash

WORKDIR=~/multicloud-k8s

cd $WORKDIR/src/orchestrator && make all
cd $WORKDIR/src/ncm && make all
cd $WORKDIR/src/rsync && make all
cd $WORKDIR/src/ovnaction && make all
cd $WORKDIR/src/clm && make all
cd $WORKDIR/src/dcm && make all

cp $WORKDIR/deployments/helm/v2/onap4k8s/orchestrator/resources/config/config.json $WORKDIR/src/orchestrator/
cp $WORKDIR/deployments/helm/v2/onap4k8s/ncm/resources/config/config.json $WORKDIR/src/ncm/
cp $WORKDIR/deployments/helm/v2/onap4k8s/rsync/resources/config/config.json $WORKDIR/src/rsync/
cp $WORKDIR/deployments/helm/v2/onap4k8s/ovnaction/resources/config/config.json $WORKDIR/src/ovnaction/
cp $WORKDIR/deployments/helm/v2/onap4k8s/clm/resources/config/config.json $WORKDIR/src/clm/
cat > $WORKDIR/src/dcm/config.json << EOF
{
    "database-ip": "172.18.0.2",
    "database-type": "mongo",
    "plugin-dir": "plugins",
    "service-port": "9015",
    "ca-file": "ca.cert",
    "server-cert": "server.cert",
    "server-key": "server.key",
    "password": "",
    "etcd-ip": "172.18.0.3",
    "etcd-cert": "",
    "etcd-key": "",
    "etcd-ca-file": ""
}
EOF

