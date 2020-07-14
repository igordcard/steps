#!/bin/bash

# based on start-dev.sh: https://github.com/onap/multicloud-k8s/blob/master/deployments/start-dev.sh
# run as root

set -o errexit
set -o nounset
set -o pipefail

cd ~/multicloud-k8s/deployments
source _functions.sh

#
# Start k8splugin from compiled binaries to foreground. This is usable for development use.
#
source /etc/environment
k8s_path="$(git rev-parse --show-toplevel)"

apt-get install -y docker-compose build-essential

stop_all
start_mongo
# install etcd
cat >> docker-compose.yml << \EOF
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
export ETCD_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -aqf "name=etcd"))

# prep config for dcm via orchestrator config.go
pushd $k8s_path/src/orchestrator/pkg/infra/config
sed -i "s/DatabaseIP:             \"127.0.0.1\"/DatabaseIP:             \"$DATABASE_IP\"/" config.go
sed -i "s/EtcdIP:                 \"127.0.0.1\"/EtcdIP:                 \"$ETCD_IP\"/" config.go
popd

echo "Compiling source code"
pushd $k8s_path/src/dcm/
#generate_k8sconfig
# cat > k8sconfig.json << EOF
# {
#     "database-address": "$DATABASE_IP",
#     "database-ip": "$DATABASE_IP",
#     "database-type": "mongo",
#     "plugin-dir": "plugins",
#     "service-port": "9015",
#     "ca-file": "ca.cert",
#     "server-cert": "server.cert",
#     "server-key": "server.key",
#     "password": "",
#     "etcd-ip": "127.0.0.1",
#     "etcd-cert": "",
#     "etcd-key": "",
#     "etcd-ca-file": ""
# }
# EOF
# source ~/.profile
make all
./dcm
popd
