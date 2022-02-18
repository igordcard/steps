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

## install monitor on each cluster
helm install monitor monitor-helm-root-latest.tgz --kubeconfig ~/c01.config
helm install monitor monitor-helm-root-latest.tgz --kubeconfig ~/c02.config
#helm install monitor monitor-helm-latest.tgz --kubeconfig ~/c01.config
#helm install monitor monitor-helm-latest.tgz --kubeconfig ~/c02.config

