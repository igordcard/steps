#!/bin/bash

cd /root/emco-base/deployments/helm/emcoBase
make lint-clm
make clean
make all
