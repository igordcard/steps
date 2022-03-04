# 20220210+
# run as root
# distro tested: ubuntu 20.04

# look up phantom emco resources in emco clusters:
kubectl get ns && kubectl get csr && kubectl get pods -A && kubectl get resourcebundlestate && kubectl get crd


# rebuild EMCO as Docker containers

## (once) set docker daemon registry settings to insecure and setup registry [dev purposes only]
export docker_address=192.168.121.1:5000 # IP of dev (local) machine via libvirt vswitch / where EMCO services run
cat > /etc/docker/daemon.json << EOF
{
  "insecure-registries" : ["$docker_address"]
}
EOF
systemctl restart docker
docker run -d -p 5000:5000 --name registry registry:2.7

## rebuild all images
export EMCODOCKERREPO=$docker_address/
export BUILD_CASE=DEV_TEST
docker pull alpine:3.12                              
docker tag alpine:3.12 $docker_address/alpine:3.12
make build-base
make deploy

## also setup docker to be insecure in each of the clusters
export docker_address=192.168.121.1:5000 # use same IP as above
cat > /etc/docker/daemon.json << EOF
{
  "insecure-registries" : ["$docker_address"]
}
EOF
systemctl restart docker

## and if using alvistack's CRI-O-based k8s boxes then change this one instead:
### REF(fix-crio)
cat >> /etc/containers/registries.conf << EOF

[[registry]]
location="$docker_address"
insecure=true
EOF
systemctl restart crio

# figuring out changes to Makefile for k8s1.23 + go1.17:
export EMCODOCKERREPO=192.168.121.1:5000/
export BUILD_CAUSE=DEV_TEST
export MODS="monitor clm dcm orchestrator rsync dtc tools/emcoctl nps sds its"
make deploy


# updated vagrant cluster access configuration (4 samples for k8s 1.20-1.23)
vagrant up
export k231=$(vagrant ssh-config | grep HostName | cut -f 4 -d " ")
sed -i '/k231/d' ~/.bashrc
echo "export k231=$k231" >> ~/.bashrc
ssh-copy-id -f -i ~/.ssh/id_rsa.pub -o "IdentityFile .vagrant/machines/default/libvirt/private_key" -o StrictHostKeyChecking=no vagrant@$k231
ssh vagrant@$k231 -t "sudo su -c 'mkdir /root/.ssh; cp /home/vagrant/.ssh/authorized_keys /root/.ssh/'"
scp $k231:~i/.kube/config /root/clusters/k23-1.conf
# don't forget to allow insecure registry here
### SEE(fix-crio)

vagrant up
sed -i '/k221/d' ~/.bashrc
echo "export k221=$k221" >> ~/.bashrc
ssh-copy-id -f -i ~/.ssh/id_rsa.pub -o "IdentityFile .vagrant/machines/default/libvirt/private_key" -o StrictHostKeyChecking=no vagrant@$k221
ssh vagrant@$k221 -t "sudo su -c 'mkdir /root/.ssh; cp /home/vagrant/.ssh/authorized_keys /root/.ssh/'"
scp $k221:~/.kube/config /root/clusters/k22-1.conf
# don't forget to allow insecure registry here
### SEE(fix-crio)

vagrant up
export k211=$(vagrant ssh-config | grep HostName | cut -f 4 -d " ")
sed -i '/k211/d' ~/.bashrc
echo "export k211=$k211" >> ~/.bashrc
ssh-copy-id -f -i ~/.ssh/id_rsa.pub -o "IdentityFile .vagrant/machines/default/libvirt/private_key" -o StrictHostKeyChecking=no vagrant@$k211
ssh vagrant@$k211 -t "sudo su -c 'mkdir /root/.ssh; cp /home/vagrant/.ssh/authorized_keys /root/.ssh/'"
scp $k211:~/.kube/config /root/clusters/k21-1.conf
# don't forget to allow insecure registry here
### SEE(fix-crio)

vagrant up
export k201=$(vagrant ssh-config | grep HostName | cut -f 4 -d " ")
sed -i '/k201/d' ~/.bashrc
echo "export k201=$k201" >> ~/.bashrc
ssh-copy-id -f -i ~/.ssh/id_rsa.pub -o "IdentityFile .vagrant/machines/default/libvirt/private_key" -o StrictHostKeyChecking=no vagrant@$k201
ssh vagrant@$k201 -t "sudo su -c 'mkdir /root/.ssh; cp /home/vagrant/.ssh/authorized_keys /root/.ssh/'"
scp $k201:~/.kube/config /root/clusters/k20-1.conf
# don't forget to allow insecure registry here
### SEE(fix-crio)


## install monitor on each cluster:
helm install monitor $EMCO_DIR/bin/helm/monitor-helm-latest.tgz --kubeconfig ~/clusters/k23-1.conf

## or do it without the package helm charts:
cd $EMCO_DIR/deployments/helm/monitor
sed -i 's/172.25.103.10/192.168.121.1/' values.yaml
#sed -i 's/root-latest/latest/' values.yaml # depends on the situation
helm install monitor . --kubeconfig ~/clusters/k23-1.conf
## and to remove:
helm uninstall monitor --kubeconfig ~/clusters/k23-1.conf
