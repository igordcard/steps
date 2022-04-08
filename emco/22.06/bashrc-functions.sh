#!/bin/bash

hardreset_emco() {
        ns="privileged-lc-ns"
        killall dcm
        killall rsync
        killall orchestrator
        ETCDCTL_API=3 etcdctl --endpoints http://$ETCD_IP:2379 del "" --from-key=true
        mongo $MONGO_IP/emco --eval "db.resources.remove({})"
        ssh $k221 -C "kubectl delete ns $ns;kubectl delete resourcebundlestate --all; kubectl delete csr --all"
        ssh $k231 -C "kubectl delete ns $ns;kubectl delete resourcebundlestate --all; kubectl delete csr --all"
        sleep 2
        echo "ATTENTION: Only deleting namespace $ns on the edge clusters..."
        cd $EMCO_DIR/bin/orchestrator
        ./orchestrator >> log.txt 2>&1 &
        sleep 2
        cd $EMCO_DIR/bin/rsync
        ./rsync >> log.txt 2>&1 &
        cd $EMCO_DIR/bin/dcm
        ./dcm >> log.txt 2>&1 &
}
