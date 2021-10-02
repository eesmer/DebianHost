#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
apt-get -y install php php-gd php-curl php-zip php-xml php-mbstring
apt-get -y install php-intl php-bcmath php-gmp php-imagick imagemagick php-bz2
apt-get -y install apache2 libapache2-mod-php
apt-get -y install mariadb-server php-mysql
apt-get -y install wget zip
apt-get -y install pwgen

NC_VER=22.1.1
wget https://download.nextcloud.com/server/releases/nextcloud-$NC_VER.zip -O /tmp/nextcloud-$NC_VER.zip

cd /var/www/html
unzip /tmp/nextcloud-$NC_VER.zip
chown -R www-data:www-data nextcloud
chmod -R 755 nextcloud

#-----------------
# CREATE DATABASE
#-----------------
DBNAME=nextclouddb
DBUSER=nextclouddbuser
DBPASS=$(pwgen -cyB -N 1)

mysql -e "DROP DATABASE IF EXISTS ${DBNAME};"
mysql -e "DROP USER IF EXISTS '${DBUSER}'@'localhost';"

mysql -e "CREATE DATABASE ${DBNAME} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
mysql -e "CREATE USER ${DBUSER}@localhost IDENTIFIED BY '${DBPASS}';"
mysql -e "GRANT ALL PRIVILEGES ON ${DBNAME}.* TO '${DBUSER}'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

cat > /usr/local/debianhost/.nextcloud_info << EOF
# Nextcloud DB Info
DBNAME: $DBNAME
DBUSER: $DBUSER
DBPASS: $DBPASS
EOF

#-----------------
# WEB CONFIG
#-----------------
rm /etc/apache2/sites-enabled/000-default.conf
rm /etc/apache2/sites-available/000-default.conf

cat > /etc/apache2/sites-available/000-default.conf << EOF
<VirtualHost *:80>
ServerAdmin webmaster@localhost
DocumentRoot /var/www/html/nextcloud/
ServerName nextcloud.example.com
Alias   /nextcloud "/var/www/html/nextcloud/"

<Directory /var/www/html/nextcloud/>
Options +FollowSymlinks
AllowOverride All
Require all granted 
<IfModule mod_dav.c>
Dav off
</IfModule>
SetEnv HOME /var/www/html/nextcloud
SetEnv HTTP_HOME /var/www/html/nextcloud
</Directory>

ErrorLog ${APACHE_LOG_DIR}/error.log
CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
chmod 644 /etc/apache2/sites-available/000-default.conf
cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-enabled/

a2enmod rewrite && a2enmod headers && a2enmod env && a2enmod dir && a2enmod mime
systemctl restart apache2
