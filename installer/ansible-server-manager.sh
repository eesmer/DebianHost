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
echo "   |--------------------------------------------------|"
echo "   | DebianHost Ansible Manager                       |"
echo "   |--------------------------------------------------|"
echo "   | Manage Linux Host    | Manage Windows Host       |"
echo "   |--------------------------------------------------|"
echo "   | 1. ping              | 20. ping                  |"
echo "   |--------------------------------------------------|"
echo "   | 2. install package   | 21. install   .msi        |"
echo "   | 3. remove package    | 22. uninstall .msi        |"
echo "   |--------------------------------------------------|"
echo "   |                      | 23. Restart Service       |"
echo "   |                      |---------------------------|"
echo "   |                      | 29. Set Connection vars   |"
echo "   |--------------------------------------------------|"
echo "   | 49. Host List                                    |"
echo "   | 50. Add Host                                     |"
echo "   |--------------------------------------------------|"
echo "   | 99.Exit                                          |"
echo "   |--------------------------------------------------|"
}

function add_host(){
echo "add/remove machine"
ln -sf /etc/ansible/hosts /usr/local/hosts
vim /usr/local/reman/hosts
pause
}

function host_list() {
egrep "^[0-9a-zA-Z]" /etc/ansible/hosts |cut -d '#' -f1 |awk '{ print $1 }' | sort | uniq > /tmp/hosts.txt
let i=0
W=()
while read -r line; do
	let i=$i+1
	W+=($i "$line")
done < <( cat /tmp/hosts.txt)
IND=$(whiptail --title "Select Host" --menu "Chose one" 24 50 17 "${W[@]}" 3>&2 2>&1 1>&3)
HOST=$(sed -n $IND\p /tmp/hosts.txt)
echo $HOST
}

function ping_linux(){
echo "Ping Test"
host_list
ansible $HOST -m ping
pause
}

function ping_windows(){
echo "Ping Test"
host_list
ansible $HOST -m win_ping
pause
}

function install_msi(){
echo "install .msi"
host_list
MSI_PATH=$(whiptail --title "msi Path" --inputbox "Where is the .msi package?" 10 60  3>&1 1>&2 2>&3)

cat > /tmp/install_msi.yml <<EOF
---
- name: install msi
  hosts: $HOST

  tasks:
         - name: install msi
           win_package:
                   path: $MSI_PATH
                   state: present
EOF
ansible-playbook /tmp/install_msi.yml
rm /tmp/install_msi.yml
pause
}

function download_install_msi(){
echo "download and install .msi"
host_list
DOWNLOAD_LINK=$(whiptail --title "MSI Download Link" --inputbox "MSI Download Link" 10 60  3>&1 1>&2 2>&3)
DEST_PATH=$(whiptail --title "MSI Destination Path" --inputbox "MSI Destination Path" 10 60  3>&1 1>&2 2>&3)

cat > /tmp/download_install_msi.yml <<EOF
---
- name: Download and install .msi
  hosts: $HOST

  tasks:
         - name: download msi
           win_get_url:
                   url: $DOWNLOAD_LINK
                   dest: $DEST_PATH
         - name: install msi
           win_package:
                   path: $DEST_PATH
                   state: present
EOF
ansible-playbook /tmp/download_install_msi.yml
rm /tmp/download_install_msi.yml
pause
}

function uninstall_msi(){
echo "uninstall .msi"
host_list
MSI_PATH=$(whiptail --title "msi Path" --inputbox "Where is the .msi package?" 10 60  3>&1 1>&2 2>&3)

cat > /tmp/uninstall_msi.yml <<EOF
---
- name: uninstall msi
  hosts: $HOST

  tasks:
         - name: uninstall msi
           win_package:
                   path: $MSI_PATH
                   state: absent
EOF
ansible-playbook /tmp/uninstall_msi.yml
rm /tmp/uninstall_msi.yml
pause
}

function set_conn_vars(){
AUSER=$(whiptail --title "Ansible User" --inputbox "Please enter the Username for Windows Host connection" 10 60  3>&1 1>&2 2>&3)
APASS=$(whiptail --title "Ansible User" --passwordbox "Please enter the Windows User Password for Windows Host connection" 10 60  3>&1 1>&2 2>&3)

if [ ! -z "$AUSER" ] || [ ! -z "$APASS" ]; then
mkdir -p /etc/ansible/group_vars
chmod 755 /etc/ansible/group_vars
cat > /etc/ansible/group_vars/win.yaml <<EOF
ansible_user: $AUSER
ansible_password: $APASS
ansible_connection: winrm
ansible_winrm_server_cert_validation: ignore
ansible_winrm_transport: basic
ansible_winrm_port: 5985
EOF
fi
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
1) ping_linux ;;
2) package_install ;;
3) package_uninstall ;;
5) package_update ;;
6) system_update ;;
20) ping_windows ;;
21) install_msi ;;
23) uninstall_msi ;;
29) set_conn_vars ;;
49) host_list ;;
50) add_host ;;
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
