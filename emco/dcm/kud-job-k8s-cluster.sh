#!/bin/bash

# run as root

mkdir -p /opt/kud/multi-cluster/{cluster-101,cluster-102}

cat > /opt/kud/multi-cluster/cluster-101/hosts.ini <<EOF
[all]
c01 ansible_ssh_host=$VAGRANT_IP_ADDR1 ansible_ssh_port=22

[kube-master]
c01

[kube-node]
c01

[etcd]
c01

[ovn-central]
c01

[ovn-controller]
c01

[virtlet]
c01

[k8s-cluster:children]
kube-node
kube-master
EOF

cat > /opt/kud/multi-cluster/cluster-102/hosts.ini <<EOF
[all]
c02 ansible_ssh_host=$VAGRANT_IP_ADDR2 ansible_ssh_port=22

[kube-master]
c02

[kube-node]
c02

[etcd]
c02

[ovn-central]
c02

[ovn-controller]
c02

[virtlet]
c02

[k8s-cluster:children]
kube-node
kube-master
EOF

kubectl config use-context kubernetes-admin@kubernetes

# launch the jobs that install k8s on the VMs
CLUSTER_NAME=cluster-101
cat <<EOF | kubectl create -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: kud-$CLUSTER_NAME
spec:
  template:
    spec:
      hostNetwork: true
      containers:
        - name: kud
          image: github.com/onap/multicloud-k8s:latest
          imagePullPolicy: IfNotPresent
          volumeMounts:
          - name: multi-cluster
            mountPath: /opt/kud/multi-cluster
          - name: secret-volume
            mountPath: "/.ssh"
          command: ["/bin/sh","-c"]
          args: ["cp -r /.ssh /root/; chmod -R 600 /root/.ssh; ./installer --cluster $CLUSTER_NAME --plugins onap4k8s"]
          securityContext:
            privileged: true
      volumes:
      - name: multi-cluster
        hostPath:
          path: /opt/kud/multi-cluster
      - name: secret-volume
        secret:
          secretName: ssh-key-secret
      restartPolicy: Never
  backoffLimit: 0
EOF
#./installer.sh --cluster $CLUSTER_NAME
CLUSTER_NAME=cluster-102
cat <<EOF | kubectl create -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: kud-$CLUSTER_NAME
spec:
  template:
    spec:
      hostNetwork: true
      containers:
        - name: kud
          image: github.com/onap/multicloud-k8s:latest
          imagePullPolicy: IfNotPresent
          volumeMounts:
          - name: multi-cluster
            mountPath: /opt/kud/multi-cluster
          - name: secret-volume
            mountPath: "/.ssh"
          command: ["/bin/sh","-c"]
          args: ["cp -r /.ssh /root/; chmod -R 600 /root/.ssh; ./installer --cluster $CLUSTER_NAME --plugins onap4k8s"]
          securityContext:
            privileged: true
      volumes:
      - name: multi-cluster
        hostPath:
          path: /opt/kud/multi-cluster
      - name: secret-volume
        secret:
          secretName: ssh-key-secret
      restartPolicy: Never
  backoffLimit: 0
EOF
#./installer.sh --cluster $CLUSTER_NAME

kubectl --kubeconfig=/opt/kud/multi-cluster/cluster-101/artifacts/admin.conf cluster-info
kubectl --kubeconfig=/opt/kud/multi-cluster/cluster-102/artifacts/admin.conf cluster-info
