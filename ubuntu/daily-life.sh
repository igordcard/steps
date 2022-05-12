#!/bin/bash

# Ubuntu 20.04
# run as root

mkdir -p /root/deb/20.04/
apt-get update && apt-get upgrade -y && apt-get dist-upgrade -y && mv /var/cache/apt/archives/*.deb /root/deb/20.04/.

mkdir /root/bash-history-rotated
cat > /etc/logrotate.d/bash_history << EOF
compress
dateext
dateformat -%Y%m%d-%s
rotate 99999
daily
copy
missingok
nomail
notifempty

/root/.bash_history {
    olddir /root/bash-history-rotated
}
EOF
logrotate -f /etc/logrotate.d/bash_history
