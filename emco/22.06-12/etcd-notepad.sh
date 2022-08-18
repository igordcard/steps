# Get all keys from etcd
ETCDCTL_API=3 etcdctl --endpoints http://$ETCD_IP:2379 get --prefix / --keys-only

# Get all keys from etcd (with contents)
ETCDCTL_API=3 etcdctl --endpoints http://$ETCD_IP:2379 get --prefix /