#!/bin/bash

# Show all appcontext keys:
ETCDCTL_API=3 etcdctl --endpoints http://$ETCD_IP:2379 get --prefix /context/ --keys-only

# Show appcontext status:
ETCDCTL_API=3 etcdctl --endpoints http://$ETCD_IP:2379 get --prefix /context/ | tail

# Show MongoDB orchestrator store contents:
mongo $DATABASE_IP/mco --eval 'db.orchestrator.find()'

# Wipe out etcd, just in case:
ETCDCTL_API=3 etcdctl --endpoints http://$ETCD_IP:2379 del "" --from-key=true

# Show that kubeconfig works:
kubectl get secrets -A
kubectl get secrets -n ns1
kubectl config current-context
kubectl config view
kubectl get secrets -A
kubectl get secrets -n ns1

# Sequence diagram for CSR approval:
# https://wiki.onap.org/display/DW/Obtaining+signed+certificate
