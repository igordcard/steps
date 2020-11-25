#!/bin/bash

# Show all appcontext keys:
ETCDCTL_API=3 etcdctl --endpoints http://$ETCD_IP:2379 get --prefix /context/ --keys-only

# Show appcontext status:
ETCDCTL_API=3 etcdctl --endpoints http://$ETCD_IP:2379 get --prefix /context/ | tail

# Get particular appcontext path:
ETCDCTL_API=3 etcdctl --endpoints http://$ETCD_IP:2379 get /context/7892661236820160162/app/logical-cloud/cluster/cp+c1/

# Show MongoDB store collections:
mongo $MONGO_IP/mco --eval 'db.cluster.find()'
mongo $MONGO_IP/mco --eval 'db.cloudconfig.find()'
mongo $MONGO_IP/mco --eval 'db.orchestrator.find()'

# Delete specific MongoDB document by ID:
mongo $MONGO_IP/mco --eval 'db.orchestrator.remove({"_id" : ObjectId("5fb42624bbc56bb17e02b5d7")})'

# Delete all MongoDB records except one:
mongo $MONGO_IP/mco --eval 'db.orchestrator.remove({"_id" : { $ne: ObjectId("5fb4228dbbc56bb17e02b392")}})'

# Update specific MongoDB document by ID:
mongo $MONGO_IP/mco --eval 'db.orchestrator.update({"_id" : ObjectId("5fb4228dbbc56bb17e02b392")}, { "_id" : ObjectId("5fb4228dbbc56bb17e02b392"), "project" : "test-project", "key" : "{project,}", "projectmetadata" : { "metadata" : { "name" : "test-project", "description" : "description of test-project project", "userdata1" : "test-project user data 1", "userdata2" : "test-project user data 2" } } })'
mongo $MONGO_IP/mco --eval 'db.cluster.update({"_id" : ObjectId("5fb5f804bbc56bb17e03e36b")}, { "_id" : ObjectId("5fb5f804bbc56bb17e03e36b"), "cluster" : "c1", "label" : "LabelA", "provider" : "cp", "clustermetadata" : { "labelname" : "LabelA" }, "key" : "{cluster,label,provider,}" })'

# Reset typical EMCO collections to a fresh-ish state
mongo $MONGO_IP/mco --eval 'db.cloudconfig.remove({"cluster":"c1","level":"1"})'

# Wipe out etcd, just in case:
ETCDCTL_API=3 etcdctl --endpoints http://$ETCD_IP:2379 del "" --from-key=true

# Delete every key under the specified level:
ETCDCTL_API=3 etcdctl --endpoints http://$ETCD_IP:2379 del --prefix /context/

# Show that kubeconfig works:
kubectl get secrets -A
kubectl get secrets -n ns1
kubectl config current-context
kubectl config view
kubectl get secrets -A
kubectl get secrets -n ns1

# In the clusters:
kubectl delete namespace ns1 && kubectl delete csr lc1-user-csr && kubectl delete resourcebundlestates --all