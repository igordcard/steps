#!/bin/bash

cd ~/multicloud-k8s
docker build -f build/Dockerfile . -t emco
