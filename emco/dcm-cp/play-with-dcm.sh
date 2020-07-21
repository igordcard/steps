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
curl -X POST localhost:9015/v2/projects/test-project/logical-clouds/lc1/apply