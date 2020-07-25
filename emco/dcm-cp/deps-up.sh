#!/bin/bash
# setup EMCO dependencies MongoDB and etcd

apt-get install -y docker-compose build-essential

WORKDIR=~/multicloud-k8s

cd $WORKDIR/deployments
source _functions.sh
source /etc/environment

# install MongoDB
stop_all
start_mongo
echo $DATABASE_IP

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
echo $ETCD_IP

# as an extra add the vars to bashrc so they're always in the env
sed -i '/DATABASE_IP/d' ~/.bashrc
echo "export DATABASE_IP=$DATABASE_IP" >> ~/.bashrc
sed -i '/ETCD_IP/d' ~/.bashrc
echo "export ETCD_IP=$ETCD_IP" >> ~/.bashrc