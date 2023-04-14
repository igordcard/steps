#!/bin/basj

# 20230414-

# prerequisites: update proxies in /etc/environment and /etc/profile.d/proxy.sh

# update $HOME/.profile:
PATH="/usr/local/go/bin:$PATH"
PATH="$HOME/go/bin:$PATH"

wget https://go.dev/dl/go1.20.3.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.20.3.linux-amd64.tar.gz
go install sigs.k8s.io/kind@v0.18.0

sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
apt-cache policy docker-ce
sudo apt-get install docker-ce
sudo systemctl status docker
sudo usermod -aG docker ${USER}
exit
docker version
docker info
docker run hello-world
sudo mkdir -p /etc/systemd/system/docker.service.d/
sudo vim /etc/systemd/system/docker.service.d/http-proxy.conf
# add proxy config for docker here
sudo systemctl daemon-reload
sudo systemctl restart docker
# 1/2: fill in certificate-specific configs here
sudo update-ca-certificates
sudo service docker restart
sudo su
# 2/2: fill in certificate-specific configs here
service docker restart
exit
docker run hello-world

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin

kind create cluster
kubectl cluster-info --context kind-kind
kubectl get pods -A
