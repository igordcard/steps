#!/bin/bash

# bionic

# first get k8s up and running with kubeadm1
# kubeadm-up.sh

# now istio
curl -L https://istio.io/downloadIstio | sh -
cd istio-1.5.1/
export PATH=$PWD/bin:$PATH