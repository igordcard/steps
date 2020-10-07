#!/bin/bash

# install
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
sudo apt-get install apt-transport-https --yes
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm2

# setup
helm init
make repo
make clean
make all

# deploy
helm install dist/packages/emco-db-0.1.0.tgz --name emco-db --namespace emco
helm install dist/packages/emco-services-0.1.0.tgz --name emco-services --namespace emco
helm install dist/packages/emco-tools-0.1.0.tgz --name emco-tools --namespace emco
# elm install dist/packages/emco-0.1.0.tgz --name emco --namespace emco

# undeploy
helm delete emco-tools --purge
helm delete emco-services --purge
helm delete emco-db --purge
#helm delete emco --purge
make repo-stop
