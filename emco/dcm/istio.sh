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
#ssh root@$VAGRANT_IP_ADDR1
export ISTIO_VERSION=1.6.4
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
#ssh root@$VAGRANT_IP_ADDR2
# repeat above for second cluster

# logout back to global cluster

############### global cluster ###############

# get IPs of each cluster in a different shell
#export VAGRANT_IP_ADDR1=192.168.121.112
#export VAGRANT_IP_ADDR2=192.168.121.223

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
kubectl config use-context kubernetes-admin@kubernetes

#kubectl config use-context kubernetes-admin@kubernetes
#kubectl config use-context cluster-101-admin@cluster-101
#kubectl config use-context cluster-102-admin@cluster-102

export CTX_CLUSTER1=$(kubectl config view -o jsonpath='{.contexts[0].name}')
export CTX_CLUSTER2=$(kubectl config view -o jsonpath='{.contexts[1].name}')

# install CoreDNS>1.4.0 on cluster 1
kubectl config use-context $CTX_CLUSTER1
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

# install CoreDNS>1.4.0 on cluster 2
kubectl config use-context $CTX_CLUSTER2
# > repeat step above.

kubectl create --context=$CTX_CLUSTER1 namespace foo
kubectl label --context=$CTX_CLUSTER1 namespace foo istio-injection=enabled
kubectl apply --context=$CTX_CLUSTER1 -n foo -f samples/sleep/sleep.yaml
export SLEEP_POD=$(kubectl get --context=$CTX_CLUSTER1 -n foo pod -l app=sleep -o jsonpath={.items..metadata.name})

kubectl create --context=$CTX_CLUSTER2 namespace bar
kubectl label --context=$CTX_CLUSTER2 namespace bar istio-injection=enabled
kubectl apply --context=$CTX_CLUSTER2 -n bar -f samples/httpbin/httpbin.yaml

# the following doesn't work, so I assume I need node port instead of load balancer:
#export CLUSTER2_GW_ADDR=$(kubectl get --context=$CTX_CLUSTER2 svc --selector=app=istio-ingressgateway \
#    -n istio-system -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')

# so do this: https://istio.io/latest/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports:
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}' --context=$CTX_CLUSTER2)
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}' --context=$CTX_CLUSTER2)
export TCP_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="tcp")].nodePort}' --context=$CTX_CLUSTER2)
export INGRESS_NODEPORT=$(kubectl --context=$CTX_CLUSTER2 get svc -n istio-system istio-ingressgateway -o=jsonpath='{.spec.ports[?(@.port==15443)].nodePort}')

# going to risk it and assume the ingress IP (for the node port) I'm looking for is the one of the cluster:
export INGRESS_HOST=$VAGRANT_IP_ADDR2
export CLUSTER2_GW_ADDR=$VAGRANT_IP_ADDR2

kubectl apply --context=$CTX_CLUSTER1 -n foo -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: httpbin-bar
spec:
  hosts:
  # must be of form name.namespace.global
  - httpbin.bar.global
  # Treat remote cluster services as part of the service mesh
  # as all clusters in the service mesh share the same root of trust.
  location: MESH_INTERNAL
  ports:
  - name: http1
    number: 8000
    protocol: http
  resolution: DNS
  addresses:
  # the IP address to which httpbin.bar.global will resolve to
  # must be unique for each remote service, within a given cluster.
  # This address need not be routable. Traffic for this IP will be captured
  # by the sidecar and routed appropriately.
  - 240.0.0.2
  endpoints:
  # This is the routable address of the ingress gateway in cluster2 that
  # sits in front of sleep.foo service. Traffic from the sidecar will be
  # routed to this address.
  - address: ${CLUSTER2_GW_ADDR}
    ports:
      http1: ${INGRESS_PORT} # Do not change this port value
EOF

kubectl exec --context=$CTX_CLUSTER1 $SLEEP_POD -n foo -c sleep -- curl -I httpbin.bar.global:8000/headers
# this did not work at all

# moving on to https://istio.io/latest/docs/setup/install/multicluster/gateways/#send-remote-traffic-via-an-egress-gateway
export CLUSTER1_EGW_ADDR=$(kubectl get --context=$CTX_CLUSTER1 svc --selector=app=istio-egressgateway \
    -n istio-system -o yaml -o jsonpath='{.items[0].spec.clusterIP}')

kubectl apply --context=$CTX_CLUSTER1 -n foo -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: httpbin-bar
spec:
  hosts:
  # must be of form name.namespace.global
  - httpbin.bar.global
  location: MESH_INTERNAL
  ports:
  - name: http1
    number: 8000
    protocol: http
  resolution: STATIC
  addresses:
  - 240.0.0.2
  endpoints:
  - address: ${CLUSTER2_GW_ADDR}
    network: external
    ports:
      http1: ${INGRESS_PORT} # Do not change this port value
  - address: ${CLUSTER1_EGW_ADDR}
    ports:
      http1: ${INGRESS_PORT}
EOF

kubectl exec --context=$CTX_CLUSTER1 $SLEEP_POD -n foo -c sleep -- curl -I httpbin.bar.global:8000/headers
# doesn't work either

# cleanup
kubectl delete --context=$CTX_CLUSTER1 -n foo -f samples/sleep/sleep.yaml
kubectl delete --context=$CTX_CLUSTER1 -n foo serviceentry httpbin-bar
kubectl delete --context=$CTX_CLUSTER1 ns foo
kubectl delete --context=$CTX_CLUSTER2 -n bar -f samples/httpbin/httpbin.yaml
kubectl delete --context=$CTX_CLUSTER2 ns bar
kubectl delete --context=$CTX_CLUSTER1 ns istio-system
kubectl delete --context=$CTX_CLUSTER2 ns istio-system
unset SLEEP_POD CLUSTER2_GW_ADDR CLUSTER1_EGW_ADDR CTX_CLUSTER1 CTX_CLUSTER2

istioctl manifest generate \
    -f manifests/examples/multicluster/values-istio-multicluster-gateways.yaml \
    | kubectl delete -f -
kubectl delete secret generic cacerts -n istio-system

# delete deployments according to v2test/steps.sh as well
# and wipe out k8s/docker:
cd ~/multicloud-k8s/kud/hosting_providers/vagrant
ansible-playbook -i inventory/hosts.ini /opt/kubespray-2.12.6/reset.yml --become --become-user=root -e reset_confirmation=yes
docker image ls -a -q | xargs -r docker rmi -f
apt-get purge docker-* -y --allow-change-held-packages
reboot