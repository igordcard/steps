#!/bin/bash

# not meant as a script, meant as a copypad
# run as root

# 20220203+

apt-get install docker.io
# if not root: sudo usermod -aG docker SOMEUSERNAME
systemctl enable --now docker

# should read Docker version 20.10.7, build 20.10.7-0ubuntu5~20.04.2
docker --version

export HTTPS_PROXY=http://ADDRESS:911
https://github.com/igordcard/chameleonsocks.git


cp redsocks.conf /etc/
export SOCKS_PROXY_ADDR=proxy-us.intel.com
export SOCKS_PROXY_PORT=1080
export SOCKS_PROXY_TYPE=socks5

#sed -i 's/proxy.mine.com/ADDRESS/' redsocks.conf


./c