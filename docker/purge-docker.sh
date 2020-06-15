#!/bin/bash
docker image ls -a -q | xargs -r docker rmi -f
apt-get purge docker-* -y --allow-change-held-packages