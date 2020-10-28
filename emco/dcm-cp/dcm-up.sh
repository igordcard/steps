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

#stop_all
#start_mongo
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
export DATABASE_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -aqf "name=mongo"))

# prep config for dcm via orchestrator config.go
pushd $k8s_path/src/orchestrator/pkg/infra/config
sed -i "s/DatabaseIP:             \"127.0.0.1\"/DatabaseIP:             \"$DATABASE_IP\"/" config.go
sed -i "s/EtcdIP:                 \"127.0.0.1\"/EtcdIP:                 \"$ETCD_IP\"/" config.go
popd

# compile all services
cd $k8s_path
make compile-container

# orchestrator's config.json:
mkdir -p $k8s_path/bin/orchestrator
pushd $k8s_path/bin/orchestrator
cat > config.json << EOF
{
    "ca-file": "ca.cert",
    "server-cert": "server.cert",
    "server-key": "server.key",
    "password": "",
    "database-ip": "$DATABASE_IP",
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
mkdir -p $k8s_path/bin/clm
pushd $k8s_path/bin/clm
cat > config.json << EOF
{
    "database-type": "mongo",
    "database-ip": "$DATABASE_IP",
    "etcd-ip": "$ETCD_IP",
    "service-port": "9061",
    "log-level": "trace"
}
EOF

# rsync's config.json:
mkdir -p $k8s_path/bin/rsync
pushd $k8s_path/bin/rsync
cat > config.json << EOF
{
    "database-type": "mongo",
    "database-ip": "$DATABASE_IP",
    "etcd-ip": "$ETCD_IP",
    "service-port": "9031",
    "log-level": "trace"
}
EOF

# ncm's config.json:
mkdir -p $k8s_path/bin/ncm
pushd $k8s_path/bin/ncm
cat > config.json << EOF
{
    "database-type": "mongo",
    "database-ip": "$DATABASE_IP",
    "etcd-ip": "$ETCD_IP",
    "service-port": "9041",
    "log-level": "trace"
}
EOF

echo "Compiling source code"
mkdir -p $k8s_path/bin/dcm
pushd $k8s_path/bin/dcm
#generate_k8sconfig
cat > config.json << EOF
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
    "etcd-ca-file": "",
    "log-level": "trace"
}
EOF

# ovnaction's config.json:
mkdir -p $k8s_path/bin/ovnaction
pushd $k8s_path/bin/ovnaction
cat > config.json << EOF
{
    "database-type": "mongo",
    "database-ip": "$DATABASE_IP",
    "etcd-ip": "$ETCD_IP",
    "service-port": "9051",
    "log-level": "trace"
}
EOF

source ~/.profile
make all
./dcm
popd
