#!/bin/bash
# run as root

# workaround ubuntu 18.04 bug
mv /usr/bin/docker-credential-secretservice /usr/bin/docker-credential-secretservice.bak

cd multicloud-k8s/src/monitor
docker build -f build/Dockerfile . -t monitor
docker login --username igordcard
docker tag IMAGE_ID igordcard/monitor:latest
docker push igordcard/monitor:latest

# use this monitor image
#sed -i "s/ewmduck/igordcard/" deploy/operator.yaml
kubectl delete -f deploy/operator.yaml
docker image rm igordcard/monitor:latest
docker image rm ewmduck/monitor:latest
docker image rm emcov2/monitor:latest
kubectl apply -f deploy/operator.yaml