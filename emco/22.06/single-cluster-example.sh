#!/bin/bash

hardreset_emco

cd /root/emco-base/examples/single-cluster
./setup.sh cleanup
vim config # modify config
./setup.sh create

emcoctl --config emco-cfg.yaml apply -f prerequisites.yaml -v values.yaml -s
emcoctl --config emco-cfg.yaml apply -f instantiate-lc.yaml -v values.yaml -s
emcoctl --config emco-cfg.yaml apply -f test-prometheus-collectd-deployment.yaml -v values.yaml -s
emcoctl --config emco-cfg.yaml apply -f test-prometheus-collectd-instantiate.yaml -v values.yaml -s


# check what's up in cluster:
kubectl get ns && kubectl get csr && kubectl get pods -A && kubectl get resourcebundlestate && kubectl get roles -n privileged-lc-ns && kubectl get rolebindings -n privileged-lc-ns

