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

############### global cluster ###############

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

# this automates the above:
scp root@$VAGRANT_IP_ADDR1:.kube/config ~/.kube/kubeconfig-c01
scp root@$VAGRANT_IP_ADDR2:.kube/config ~/.kube/kubeconfig-c02
sed -i "s/kubernetes-admin/cluster-101-admin/" ~/.kube/kubeconfig-c01
sed -i "s/kubernetes-admin/cluster-102-admin/" ~/.kube/kubeconfig-c02

export KUBECONFIG=/root/.kube/config:/root/.kube/kubeconfig-c01:/root/.kube/kubeconfig-c02

#kubectl config use-context kubernetes-admin@kubernetes
#kubectl config use-context cluster-101-admin@cluster-101
#kubectl config use-context cluster-102-admin@cluster-102

export CTX_CLUSTER1=$(kubectl config view -o jsonpath='{.contexts[0].name}')
export CTX_CLUSTER2=$(kubectl config view -o jsonpath='{.contexts[1].name}')

# fetch istio also in the global controller now that kubeconfig is configured

export ISTIO_VERSION=1.6.3
curl -L https://istio.io/downloadIstio | sh -
cd istio-$ISTIO_VERSION
export PATH=$PWD/bin:$PATH

kubectl create --context=$CTX_CLUSTER1 namespace foo
kubectl label --context=$CTX_CLUSTER1 namespace foo istio-injection=enabled
kubectl apply --context=$CTX_CLUSTER1 -n foo -f samples/sleep/sleep.yaml
export SLEEP_POD=$(kubectl get --context=$CTX_CLUSTER1 -n foo pod -l app=sleep -o jsonpath={.items..metadata.name})

kubectl create --context=$CTX_CLUSTER2 namespace bar
kubectl label --context=$CTX_CLUSTER2 namespace bar istio-injection=enabled
kubectl apply --context=$CTX_CLUSTER2 -n bar -f samples/httpbin/httpbin.yaml

# the following doesn't work, so I assume I need node port instead of load balancer:
export CLUSTER2_GW_ADDR=$(kubectl get --context=$CTX_CLUSTER2 svc --selector=app=istio-ingressgateway \
    -n istio-system -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')

# so do this: https://istio.io/latest/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports:
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}' --context=$CTX_CLUSTER2)
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}' --context=$CTX_CLUSTER2)
export TCP_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="tcp")].nodePort}' --context=$CTX_CLUSTER2)
export INGRESS_NODEPORT=$(kubectl --context=$CTX_CLUSTER2 get svc -n istio-system istio-ingressgateway -o=jsonpath='{.spec.ports[?(@.port==15443)].nodePort}')

# going to risk it and assume the ingress IP (for the node port) I'm looking for is the  one of the cluster:
export INGRESS_HOST=$VAGRANT_IP_ADDR2
export CLUSTER2_GW_ADDR=$VAGRANT_IP_ADDR2