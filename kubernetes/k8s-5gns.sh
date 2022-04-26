#!/bin/bash
# run as root
# follow docker/install-docker.sh first

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system


apt-get update
apt-get install -y apt-transport-https ca-certificates curl

curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# for proxy configs:
mkdir -p /usr/lib/systemd/system/kubelet.service.d/
mkdir -p /etc/systemd/system/docker.service.d/
#vim /usr/lib/systemd/system/kubelet.service.d/http-proxy.conf
cp /usr/lib/systemd/system/kubelet.service.d/http-proxy.conf /usr/lib/systemd/system/docker.service.d/http-proxy.conf

systemctl daemon-reload
systemctl restart kubelet.service
systemctl restart docker.service

# disable swap
swapoff -a
vim /etc/fstab

# install k8s
kubeadm config images pull # --v=5
kubeadm init # --v=5
export KUBECONFIG=/etc/kubernetes/admin.conf
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> /root/.bashrc
nodename=$(kubectl get node -o jsonpath='{.items[0].metadata.name}')
kubectl taint node $nodename node-role.kubernetes.io/master:NoSchedule-
kubectl label --overwrite node $nodename ovn4nfv-k8s-plugin=ovn-control-plane

# install nodus
git clone https://github.com/akraino-edge-stack/icn-nodus.git
cd icn-nodus
kubectl apply -f deploy/ovn-daemonset.yaml
kubectl apply -f deploy/ovn4nfv-k8s-plugin.yaml

curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
