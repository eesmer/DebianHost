#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
apt-get -y install vim tmux htop
apt-get -y install openssh-server
apt-get -y install curl wget ack
apt-get -y install net-tools
apt-get -y install git
apt-get -y install --install-recommends lxc debootstrap bridge-utils

rm -r /usr/local/debianhost
git clone https://github.com/eesmer/DebianHost.git

cp -R DebianHost /usr/local/debianhost/
chown -R root:root /usr/local/debianhost
chmod -R 755 /usr/local/debianhost
cp /usr/local/debianhost/manager /usr/local/sbin/manager
chmod +x /usr/local/sbin/manager

lxc-create -n template-container -t download -P /var/lib/lxc/ -- -d debian -r buster -a amd64 --keyserver hkp://keyserver.ubuntu.com
cat > /var/lib/lxc/template-container/config << EOF
# Distribution configuration
lxc.include = /usr/share/lxc/config/common.conf
lxc.arch = linux64

# Container specific configuration
lxc.include = /usr/share/lxc/config/nesting.conf
lxc.apparmor.profile = unconfined
lxc.apparmor.allow_nesting = 1

lxc.uts.name = template-container
lxc.rootfs.path = dir:/var/lib/lxc/template-container/rootfs

# Network configuration
lxc.net.0.type = veth
lxc.net.0.link = br0
lxc.net.0.name = eth0
lxc.net.0.flags = up
EOF
chmod 640 /var/lib/lxc/template-container/config
