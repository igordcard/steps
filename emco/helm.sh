#!/bin/bash

cd /root/emco-base/deployments/helm/emcoBase
#make lint-clm
make clean
make all
make upload

cd /root/emco-base/deployments/helm/emcoBase/clm
helm dependency build


# upload to gitlab package registry:
curl --request POST \
     --form 'chart=@dist/packages/clm-1.0.0.tgz' \
     --user emco-base:TOKEN_HERE \
     https://gitlab.com/api/v4/projects/29353813/packages/helm/api/22.03/charts

#curl --request POST \
#     --form 'chart=@dist/packages/clm-1.0.0.tgz' \
#     --user emco-base:TOKEN_HERE \
#     https://gitlab.com/api/v4/projects/project-emco/core/emco-base/packages/helm/api/stable/charts


# install from gitlab package registry:
#helm repo add emco-22.03 https://gitlab.com/api/v4/projects/project-emco%2Fcore%2Femco-base/packages/helm/22.03
helm repo add emco-22.03 https://gitlab.com/api/v4/projects/29353813/packages/helm/22.03
helm search repo emco-22.03
helm install emco --repo emco-22.03 emco # doesn't work in the vagrant VMs??
helm install emco emco-22.03/emco # this one does
