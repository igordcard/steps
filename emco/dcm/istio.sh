#!/bin/bash

# run as root

# setup vagrant VMs

# # if k8s already running for emco, run this first:
# kubectl delete job kud-cluster-101
# kubectl delete job kud-cluster-102
# # and on each vagrant VM:
# helm delete multicloud-onap8ks --purge
# kubectl delete deployment nfn-operator --namespace operator
# kubectl delete deployment eaa --namespace openness
# kubectl delete daemonset nfn-agent --namespace operator
# kubectl delete daemonset ovn4nfv-cni --namespace operator

# let's use whatever got deployed by emco kud job and put istio on top of it

########### do the following in each cluster ###########
export ISTIO_VERSION=1.6.3
curl -L https://istio.io/downloadIstio | sh -
cd istio-$ISTIO_VERSION
export PATH=$PWD/bin:$PATH
kubectl create namespace istio-system
kubectl create secret generic cacerts -n istio-system \
    --from-file=samples/certs/ca-cert.pem \
    --from-file=samples/certs/ca-key.pem \
    --from-file=samples/certs/root-cert.pem \
    --from-file=samples/certs/cert-chain.pem
istioctl install \
    -f manifests/examples/multicluster/values-istio-multicluster-gateways.yaml
