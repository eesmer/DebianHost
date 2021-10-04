#!/bin/bash

function pause(){
local message="$@"
[ -z $message ] && message="Press [Enter] to continue..."
read -p "$message" readEnterKey
}

MEMORY_LIMIT=$(cat /etc/php/7.3/apache2/php.ini |grep memory_limit |cut -d ";" -f1)
UPLOAD_SIZE=$(cat /etc/php/7.3/apache2/php.ini |grep upload_max_filesize |cut -d ";" -f1)
POST_SIZE=$(cat /etc/php/7.3/apache2/php.ini |grep post_max_size |cut -d ";" -f1)
OPCACHE_ENABLE=$(cat /etc/php/7.3/apache2/php.ini |grep opcache.enable= |cut -d ";" -f1)
OPCACHE_BUFFER=$(cat /etc/php/7.3/apache2/php.ini |grep opcache.interned_strings_buffer= |cut -d ";" -f1)
OPCACHE_MAX_ACCE_FILES=$(cat /etc/php/7.3/apache2/php.ini |grep opcache.max_accelerated_files= |cut -d ";" -f1)
OPCACHE_MEMORY=$(cat /etc/php/7.3/apache2/php.ini |grep opcache.memory_consumption= |cut -d ";" -f1)
OPCACHE_FREQ=$(cat /etc/php/7.3/apache2/php.ini |grep opcache.revalidate_freq= |cut -d ";" -f1)

function show_menu(){
date
echo "   |----------------------------------------------------------|"
echo "   |DebianHost Nextcloud Manager                              |"
echo "   |----------------------------------------------------------|"
echo "   | 1.Nextcloud && DB Info                                   |"
echo "   | 2.Restart Web Service                                    |"
echo "   | 3.Nextcloud Tuning                                       |"
echo "   |----------------------------------------------------------|"
echo "    $MEMORY_LIMIT"
echo "    $UPLOAD_SIZE"
echo "    $POST_SIZE"
echo "    ----------------------------------------------------------"
echo "    $OPCACHE_ENABLE"
echo "    $OPCACHE_BUFFER"
echo "    $OPCACHE_MAX_ACCE_FILES"
echo "    $OPCACHE_MEMORY"
echo "    $OPCACHE_FREQ"
echo "   |----------------------------------------------------------|"
echo "   |99.Exit                                                   |"
echo "   |----------------------------------------------------------|"
}

function nextcloud_info(){
echo "Nextcloud Info"
cat /usr/local/debianhost/.nextcloud_info
pause
}

function restart_webservice(){
echo "Restart & Status Web Servise"
systemctl restart apache2
sleep 2
systemctl status apache2
pause
}

function nextcloud_tuning(){
CHOICE=$(whiptail --title "Tuning options" --radiolist "Choose:" 15 40 6 \
	"Set Memory Limit" "" "set-memory-limit" \
	"Set Max Upload File Size" "" "set-max-upload-file-size" \
	"Set Max Post Size" "" "set-max-post-size" 3>&1 1>&2 2>&3)
case $CHOICE in
	"Set Memory Limit")
		echo "Memory Limit menu selected"
	;;
	"Set Max Upload File Size")
		echo "Set Max Upload File selected"
	;;
	"Set Max Post Size")
		echo "Set Max Post Size selected"
	;;
	*)
	;;
esac
pause
}

function read_input(){
local c
read -p "Please choose from the menu numbers.." c
case $c in
1) nextcloud_info ;;
2) restart_webservice ;;
3) nextcloud_tuning ;;
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
