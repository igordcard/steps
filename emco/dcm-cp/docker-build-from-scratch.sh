#!/bin/bash

# 1. install Go via go-up.sh

# 2. install Docker via install-docker.sh

# 3. continue:
git clone https://github.com/onap/multicloud-k8s.git
cd multicloud-k8s
docker build -f build/Dockerfile . -t emco
