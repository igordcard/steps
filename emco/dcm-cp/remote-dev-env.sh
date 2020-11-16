#!/bin/bash

# Local terminal: WSL1/2, macOS or Linux
# Visual Studio Code
# Remote-SSH
# Go
# 2 SSH hops
# VM
# tmux
# no docker or k8s

dev_ip=192.168.121.29
k8s_ip=192.168.121.203
jump_ip=10.10.110.24

# set up connection
ssh -fNT -L 2200:$dev_ip:22 root@$jump_ip
#sshvagrant2

# (one-time) ssh config:
cat >> ~/.ssh/config << EOF
Host vagrant2
HostName 127.0.0.1
Port 2200
User root
IdentityFile ~/.ssh/id_rsa
EOF

# can also port-forward services (useful with Postman):

# orchestrator
ssh -fNT -L 9015:$dev_ip:9015 root@$jump_ip
# rsync
ssh -fNT -L 9031:$dev_ip:9031 root@$jump_ip
# ncm
ssh -fNT -L 9041:$dev_ip:9041 root@$jump_ip
# ovnaction
ssh -fNT -L 9051:$dev_ip:9051 root@$jump_ip
# ovnaction (grpc)
ssh -fNT -L 9032:$dev_ip:9032 root@$jump_ip
# clm
ssh -fNT -L 9061:$dev_ip:9061 root@$jump_ip
# dcm
ssh -fNT -L 9077:$dev_ip:9077 root@$jump_ip

# Postman collection is here:
# https://github.com/onap/multicloud-k8s/blob/master/docs/EMCO.postman_collection.json