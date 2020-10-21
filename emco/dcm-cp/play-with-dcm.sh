#!/bin/bash

# Create test-project Project
cd ~/multicloud-k8s/src/orchestrator
./orchestrator &
cat > create-project.json << EOF
{"metadata": {"name": "test-project"}}
EOF
curl --header "Content-Type: application/json" --request POST --data @create-project.json http://127.0.0.1:9015/v2/projects

# Test DCM API
cd ~/multicloud-k8s/src/dcm
./dcm &
cd ~/multicloud-k8s/src/dcm/test
./dcm_call_api.sh
./dcm_call_api.sh clean

# Apply
./dcm_call_api.sh

curl -X POST 127.0.0.1:9077/v2/projects/test-project/logical-clouds/lc1/apply

ETCD_IP=172.18.0.3

# Check etcd
ETCDCTL_API=3 etcdctl --endpoints http://172.18.0.3:2379 endpoint health

# Get all keys from etcd
ETCDCTL_API=3 etcdctl --endpoints http://172.18.0.3:2379 get / --keys-only --prefix

# Get all keys with values from etcd
ETCDCTL_API=3 etcdctl --endpoints http://172.18.0.3:2379 get / --prefix

# Get value of particular key from etcd
ETCDCTL_API=3 etcdctl --endpoints http://172.18.0.3:2379 get /context/93794758105060744/app/logical-cloud/cluster/cp-1+c2/resource/instruction/order/ --prefix

# Get all key-values from etcd
ETCDCTL_API=3 etcdctl --endpoints http://172.18.0.3:2379 get "" --prefix=true

# Wipe etcd
ETCDCTL_API=3 etcdctl --endpoints http://172.18.0.3:2379 del "" --from-key=true

DATABASE_IP=172.18.0.2

# Check mongodb orchestrator contents:
mongo $DATABASE_IP/mco --eval 'db.orchestrator.find()'

# Check mongodb controller contents:
mongo $DATABASE_IP/mco --eval 'db.controller.find()'

# Update entry in mongodb (change rsync controller port number):
mongo $DATABASE_IP/mco --eval 'db.controller.update({"controller-name": "rsync"}, {"controller-name" : "rsync", "controllermetadata" : { "metadata" : { "name" : "rsync", "description" : "", "userdata1" : "", "userdata2" : "" }, "spec" : { "host" : "127.0.0.1", "port" : 9017, "type" : "", "priority" : 1 } }, "key" : "{controller-name,}"})'

### and more useful stuff:
# check dcm-up.sh

docker start XX # start mongodb after reboot
docker start YY # start etcd after reboot

