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

# let's use whatever got deployed by emco kud job (see v2test/steps.sh) and put istio on top of it

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

kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           upstream
           fallthrough in-addr.arpa ip6.arpa
        }
        prometheus :9153
        forward . /etc/resolv.conf
        cache 30
        loop
        reload
        loadbalance
    }
    global:53 {
        errors
        cache 30
        forward . $(kubectl get svc -n istio-system istiocoredns -o jsonpath={.spec.clusterIP}):53
    }
EOF

# get IPs of each cluster in a different shell
export VAGRANT_IP_ADDR1=192.168.121.112
export VAGRANT_IP_ADDR2=192.168.121.223

# at this point manually merge the ~/.kube/configs from the vagrant VMs into the main kube config
# then it should look like:
# root@pod11-node4:~# kubectl config get-contexts
# CURRENT   NAME                           CLUSTER       AUTHINFO            NAMESPACE
#           cluster-101-admin@kubernetes   cluster-101   cluster-101-admin
#           cluster-102-admin@kubernetes   cluster-102   cluster-102-admin
# *         kubernetes-admin@kubernetes    kubernetes    kubernetes-admin


