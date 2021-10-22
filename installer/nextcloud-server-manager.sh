#!/bin/bash

function pause(){
local message="$@"
[ -z $message ] && message="Press [Enter] to continue..."
read -p "$message" readEnterKey
}

PHP_VER=$(apt-cache search php |grep opcache |cut -d "-" -f1 |cut -d "p" -f3)

OPCACHE_ENABLE=$(cat /etc/php/$PHPVER/apache2/php.ini |grep opcache.enable= |cut -d ";" -f1)
OPCACHE_BUFFER=$(cat /etc/php/$PHPVER/apache2/php.ini |grep opcache.interned_strings_buffer= |cut -d ";" -f1)
OPCACHE_MAX_ACCE_FILES=$(cat /etc/php/$PHPVER/apache2/php.ini |grep opcache.max_accelerated_files= |cut -d ";" -f1)
OPCACHE_MEMORY=$(cat /etc/php/$PHPVER/apache2/php.ini |grep opcache.memory_consumption= |cut -d ";" -f1)
OPCACHE_FREQ=$(cat /etc/php/$PHPVER/apache2/php.ini |grep opcache.revalidate_freq= |cut -d ";" -f1)

function show_menu(){
date
echo "   |----------------------------------------------|"
echo "   | DebianHost Nextcloud Manager                 |"
echo "   |----------------------------------------------|"
echo "   | 1. Info                                      |"
echo "   | 2. Restart Web Service                       |"
echo "   | 3. Tuning                                    |"
echo "   | 4. Upgrade                                   |"
echo "   | 5. Backup                                    |"
echo "   |----------------------------------------------|"
echo "   | 99.Exit                                      |"
echo "   |----------------------------------------------|"
}

function info(){
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

function tuning(){
CHOICE=$(whiptail --title "Tuning options" --radiolist "Choose:" 15 40 6 \
	"Set Memory Limit" "" "set-memory-limit" \
	"Set Max Upload File Size" "" "set-max-upload-file-size" \
	"Set Max Post Size" "" "set-max-post-size" 3>&1 1>&2 2>&3)
case $CHOICE in
	"Set Memory Limit")
		MEM_LIMIT=$(whiptail --title "Set Memory Limit" --radiolist "Choose:" 15 40 6 \
			"128M" "" "128M" \
			"256M" "" "256M" \
			"512M" "" "512M" \
			"1024M" "" "1024M" \
			"2048M" "" "2048M" \
			"3072M" "" "3072M" \
			"4096M" "" "4096M" \
			"5120M" "" "5120M" 3>&1 1>&2 2>&3)
			if [ ! -z "$MEM_LIMIT" ]; then
				sed -i "/memory_limit/d" /etc/php/$PHP_VER/mods-available/php.ini
				echo "memory_limit = $MEM_LIMIT" >> /etc/php/$PHP_VER/mods-available/php.ini
				systemctl reload apache2
			fi
	;;
	"Set Max Upload File Size")
		FILE_SIZE=$(whiptail --title "Set Upload Max File Size" --radiolist "Choose:" 15 40 6 \
			"2M" "" "2M" \
			"100M" "" "100M" \
			"500M" "" "500M" \
			"1024M" "" "1024M" \
			"2048M" "" "2048M" 3>&1 1>&2 2>&3)
			if [ ! -z "$FILE_SIZE" ]; then
				sed -i "/upload_max_filesize/d" /etc/php/$PHP_VER/mods-available/php.ini
				echo "upload_max_files = $FILE_SIZE" >> /etc/php/$PHP_VER/mods-available/php.ini
				systemctl reload apache2
			fi
	;;
	"Set Max Post Size")
		POST_SIZE=$(whiptail --title "Set Max Post Size" --radiolist "Choose:" 15 40 6 \
			"2M" "" "2M" \
			"100M" "" "100M" \
			"256M" "" "256M" \
			"512M" "" "512M" \
			"1024M" "" "1024M" \
			"2048M" "" "2048M" 3>&1 1>&2 2>&3)
			if [ ! -z "$POST_SIZE" ]; then
				sed -i "/post_max_size/d" /etc/php/$PHP_VER/mods-available/php.ini
				echo "post_max_size = $POST_SIZE" >> /etc/php/$PHP_VER/mods-available/php.ini
				systemctl reload apache2
			fi
	;;
	*)
	;;
esac
pause
}

function upgrade(){
sudo -u www-data php$PHP_VER /var/www/html/nextcloud/updater/updater.phar --no-interaction
systemctl reload apache2
pause
}

function read_input(){
local c
read -p "Please choose from the menu numbers.." c
case $c in
1) info ;;
2) restart_webservice ;;
3) tuning ;;
4) upgrade ;;
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
