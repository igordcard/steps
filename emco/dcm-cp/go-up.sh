#!/bin/bash

export GO_VERSION="1.14.4"
curl -O https://storage.googleapis.com/golang/go$GO_VERSION.linux-amd64.tar.gz
tar -xvf go$GO_VERSION.linux-amd64.tar.gz
sudo mv go /usr/local
cat >> ~/.profile <<\EOF
export GOPATH=$HOME/work
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
EOF
source ~/.profile
