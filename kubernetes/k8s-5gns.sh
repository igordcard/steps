#!/bin/bash
# run as root
# Ubuntu 20.04
# follow docker/install-docker.sh first

cat <<EOF | tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

apt-get update
apt-get install -y apt-transport-https ca-certificates curl

curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# for proxy configs:
mkdir -p /usr/lib/systemd/system/kubelet.service.d/
mkdir -p /usr/lib/systemd/system/docker.service.d/
vim /usr/lib/systemd/system/kubelet.service.d/http-proxy.conf
cp /usr/lib/systemd/system/kubelet.service.d/http-proxy.conf /usr/lib/systemd/system/docker.service.d/http-proxy.conf

systemctl daemon-reload
systemctl restart kubelet.service
systemctl restart docker.service

# disable swap - this is a necessary step for kubelet!
swapoff -a
vim /etc/fstab

# install k8s
kubeadm config images pull # --v=5
#kubeadm init --apiserver-advertise-address 10.0.0.5 --control-plane-endpoint 10.0.0.5 --pod-network-cidr=10.210.0.0/16 # --v=5 # replace with correct cp node ip address
kubeadm init --kubernetes-version=1.23.6 --apiserver-advertise-address 10.0.0.5 --control-plane-endpoint 10.0.0.5 # --v=5 # replace with correct cp node ip address
export KUBECONFIG=/etc/kubernetes/admin.conf
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> /root/.bashrc
nodename=$(kubectl get node -o jsonpath='{.items[0].metadata.name}')
kubectl taint node $nodename node-role.kubernetes.io/master:NoSchedule-
kubectl taint node $nodename node-role.kubernetes.io/control-plane:NoSchedule-
kubectl taint node $nodename node.kubernetes.io/not-ready:NoSchedule-
kubectl label --overwrite node $nodename ovn4nfv-k8s-plugin=ovn-control-plane

# install nodus
git clone https://github.com/akraino-edge-stack/icn-nodus.git
cd icn-nodus
kubectl apply -f deploy/ovn-daemonset.yaml
kubectl apply -f deploy/ovn4nfv-k8s-plugin.yaml

# install helm
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash


# deploy EMCO (from git):
git clone https://gitlab.com/project-emco/core/emco-base.git
cd emco-base


# deploy EMCO (from Helm):
helm repo add emco https://gitlab.com/api/v4/projects/29353813/packages/helm/22.03
helm repo update
kubectl create namespace emco
helm install emco emco/emco  --set global.disableDbAuth=true --namespace emco

# and monitor for  the edge clusters:

# to destroy

helm uninstall emco --namespace emco

kubeadm reset --force
rm -rf /etc/cni/net.d
rm -rf /etc/kubernetes

rm -rf /etc/openvswitch
rm -rf /var/log/openvswitch
rm -rf /var/log/ovn
rm -rf /var/run/openvswitch
rm -rf /var/run/ovn


# cleanup of old k8s stuff and make sure containerd is not in the way:
apt remove -y kubeadm kubectl kubelet kubernetes-cni 
apt purge -y kube*
apt-get remove containerd
apt-get install kubeadm

