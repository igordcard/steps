#!/bin/bash

# Create test-project Project
cd ~/multicloud-k8s/src/orchestrator
./orchestrator &
cat > create-project.json << EOF
{"metadata": {"name": "test-project"}}
EOF
curl --header "Content-Type: application/json" --request POST --data @create-project.json http://127.0.0.1:9077/v2/projects

# Test DCM API
cd ~/multicloud-k8s/src/dcm
./dcm &
cd ~/multicloud-k8s/src/dcm/test
./dcm_call_api.sh
./dcm_call_api.sh clean

# Apply
./dcm_call_api.sh

curl -X POST 127.0.0.1:9077/v2/projects/test-project/logical-clouds/lc1/apply

# Check etcd
ETCDCTL_API=3 etcdctl --endpoints http://172.18.0.3:2379 endpoint health

# Get all keys from etcd
ETCDCTL_API=3 etcdctl --endpoints http://172.18.0.3:2379 get / --keys-only

# Get all key-values from etcd
ETCDCTL_API=3 etcdctl --endpoints http://172.18.0.3:2379 get "" --prefix=true

# Wipe etcd
ETCDCTL_API=3 etcdctl --endpoints http://172.18.0.3:2379 del "" --from-key=true