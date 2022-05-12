# install
kubeadm config images pull # --v=5
kubeadm init --pod-network-cidr=10.244.0.0/16
export KUBECONFIG=/etc/kubernetes/admin.conf
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> /root/.bashrc
nodename=$(kubectl get node -o jsonpath='{.items[0].metadata.name}')
kubectl taint node $nodename node-role.kubernetes.io/master:NoSchedule-
kubectl taint node $nodename node-role.kubernetes.io/control-plane:NoSchedule-
kubectl taint node $nodename node.kubernetes.io/not-ready:NoSchedule-
kubectl taint nodes --all node-role.kubernetes.io/master-

# flannel
kubectl apply -f https://github.com/coreos/flannel/raw/master/Documentation/kube-flannel.yml


# destroy
kubeadm reset --force
rm -rf /etc/cni/net.d
rm -rf /etc/kubernetes
