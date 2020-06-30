#!/bin/bash

# run as root


# prepare the host / global k8s:

ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa

git clone https://github.com/onap/multicloud-k8s.git
# + apply https://gerrit.onap.org/r/c/multicloud/k8s/+/107159
pushd multicloud-k8s/kud/hosting_providers/vagrant
./setup.sh -p libvirt
popd
pushd multicloud-k8s

# install kubernetes/docker using KUD AIO (global cluster):
sed -i 's/localhost/$HOSTNAME/' kud/hosting_providers/baremetal/aio.sh
# # remove [cmk] plugin from aio.sh:
# vim kud/hosting_providers/baremetal/aio.sh
kud/hosting_providers/baremetal/aio.sh

# if proxy is needed:
# docker build  --rm \
# 	--build-arg http_proxy=${http_proxy} \
# 	--build-arg HTTP_PROXY=${HTTP_PROXY} \
# 	--build-arg https_proxy=${https_proxy} \
# 	--build-arg HTTPS_PROXY=${HTTPS_PROXY} \
# 	--build-arg no_proxy=${no_proxy} \
# 	--build-arg NO_PROXY=${NO_PROXY} \
#   --build-arg KUD_ENABLE_TESTS=true \
#   --build-arg KUD_PLUGIN_ENABLED=true \
# 	-t github.com/onap/multicloud-k8s:latest . -f kud/build/

docker build  --rm \
    --build-arg KUD_ENABLE_TESTS=true \
    --build-arg KUD_PLUGIN_ENABLED=true \
    -t github.com/onap/multicloud-k8s:latest . -f kud/build/Dockerfile

popd

pushd multicloud-k8s/kud/hosting_providers/containerized/
./installer.sh --install_pkg
popd

# prepare the vagrant vms for the cluster:
pushd multicloud-k8s/kud/hosting_providers/containerized
cp -R testing testing2
cd testing
sed -i "s/\"ubuntu18\"/\"cluster-101\"/" Vagrantfile
sed -i "s/32768/20480/" Vagrantfile
vagrant up
export VAGRANT_IP_ADDR1=$(vagrant ssh-config | grep HostName | cut -f 4 -d " ")
ssh-copy-id -f -i ~/.ssh/id_rsa.pub -o "IdentityFile .vagrant/machines/default/libvirt/private_key" -o StrictHostKeyChecking=no vagrant@$VAGRANT_IP_ADDR1
ssh vagrant@$VAGRANT_IP_ADDR1 -t "sudo su -c 'mkdir /root/.ssh; cp /home/vagrant/.ssh/authorized_keys /root/.ssh/'"
cd ../testing2
sed -i "s/\"ubuntu18\"/\"cluster-102\"/" Vagrantfile
sed -i "s/32768/20480/" Vagrantfile
vagrant up
export VAGRANT_IP_ADDR2=$(vagrant ssh-config | grep HostName | cut -f 4 -d " ")
ssh-copy-id -f -i ~/.ssh/id_rsa.pub -o "IdentityFile .vagrant/machines/default/libvirt/private_key" -o StrictHostKeyChecking=no vagrant@$VAGRANT_IP_ADDR2
ssh vagrant@$VAGRANT_IP_ADDR2 -t "sudo su -c 'mkdir /root/.ssh; cp /home/vagrant/.ssh/authorized_keys /root/.ssh/'"
popd

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

# launch the jobs that install k8s on the VMs

kubectl create secret generic ssh-key-secret --from-file=id_rsa=/root/.ssh/id_rsa --from-file=id_rsa.pub=/root/.ssh/id_rsa.pub
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

# for testing EMCO v2 only:

cd multicloud-k8s
docker build -f build/Dockerfile . -t mco

cd deployments/helm/v2/onap4k8s
make repo
make all
# make repo-stop

# cleanup the VM clusters only
popd
pushd multicloud-k8s/kud/hosting_providers/containerized/testing
vagrant destroy -f
cd ../testing2
vagrant destroy -f
kubectl delete job kud-cluster-101
kubectl delete job kud-cluster-102
