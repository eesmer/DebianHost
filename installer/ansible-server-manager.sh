#!/bin/bash

eval `ssh-agent -s`
ssh-add /root/.ssh/*

function pause(){
local message="$@"
[ -z $message ] && message="Press [Enter] to continue..."
read -p "$message" readEnterKey
}

function show_menu(){
date
echo "   |----------------------------|"
echo "   |DebianHost Ansible Manager  |"
echo "   |----------------------------|"
echo "   | 1.add/remove machine       |"
echo "   | 2.Ping Test                |"
echo "   |----------------------------|"
echo "   | 3.Package install          |"
echo "   | 4.Package uninstall        |"
echo "   | 5.Package update           |"
echo "   |----------------------------|"
echo "   |99.Exit                     |"
echo "   |----------------------------|"
}

function add_host(){
echo "Host Ekleme-Cikartma islemi"
ln -sf /etc/ansible/hosts /usr/local/hosts
vim /usr/local/reman/hosts
pause
}

function ping_test(){
echo "Ping Test"
PINGADDR=$(whiptail --title "Group/Host info" --inputbox "Please enter group or host name" 10 60  3>&1 1>&2 2>&3)

ansible $PINGADDR -m ping
pause
}

function package_install(){
echo "Package installation"
PCKGNAME=$(whiptail --title "Package info" --inputbox "Please enter the package name" 10 60  3>&1 1>&2 2>&3)
PCKGADDR=$(whiptail --title "Group/Host info" --inputbox "Please enter group or host name" 10 60  3>&1 1>&2 2>&3)
cd /tmp
cat > package_install.yml <<EOF
---
- hosts: $PCKGADDR
  tasks:
   - name: package install
     apt: name=$PCKGNAME state=present
EOF
ansible-playbook /tmp/package_install.yml
pause
}

function package_uninstall(){
echo "Package uninstallation"
PCKGNAME=$(whiptail --title "Package info" --inputbox "Please enter the package name" 10 60  3>&1 1>&2 2>&3)
PCKGADDR=$(whiptail --title "Group/Host info" --inputbox "Please enter group or host name" 10 60  3>&1 1>&2 2>&3)
cd /tmp
cat > package_uninstall.yml <<EOF
---
- hosts: $PCKGADDR
  tasks:
   - name: package uninstall
     apt: name=$PCKGNAME state=absent
EOF
ansible-playbook /tmp/package_uninstall.yml
pause
}

function package_update(){
echo "Package update"
PCKGNAME=$(whiptail --title "Package info" --inputbox "Please enter the package name" 10 60  3>&1 1>&2 2>&3)
PCKGADDR=$(whiptail --title "Group/Host info" --inputbox "Please enter group or host name" 10 60  3>&1 1>&2 2>&3)
cd /tmp
cat > package_update.yml <<EOF
---
- hosts: $PCKGADDR
  tasks:
   - name: package install
     apt: name=$PCKGNAME state=latest
EOF
ansible-playbook /tmp/package_update.yml
pause
}

function system_update(){
echo "System update"
UPTADDR=$(whiptail --title "Group/Host info" --inputbox "Please enter group or host name" 10 60  3>&1 1>&2 2>&3)
ansible $UPTADDR -m raw -a 'DEBIAN_FRONTEND=noninteractive apt-get update && apt-get -y dist-upgrade'
pause
}

function read_input(){
local c
read -p "Please choose from the menu numbers.." c
case $c in
1) add_host ;;
2) ping_test ;;
3) package_install ;;
4) package_uninstall ;;
5) package_update ;;
6) system_update ;;
99) exit 0 ;;
*)	
echo "Selected menu not found!!"
pause
esac
}

# CTRL+C, CTRL+Z
trap '' SIGINT SIGQUIT SIGTSTP

while true
do
clear
show_menu
read_input
done
