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

