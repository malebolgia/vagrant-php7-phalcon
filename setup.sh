#!/bin/bash
# Using Trusty64 Ubuntu

#
# Install
#
echo "============    BEGIN SETUP   ============="
echo -e "----------------------------------------"
sudo apt-get install -y build-essential python-software-properties software-properties-common
sudo add-apt-repository -y ppa:ondrej/php
sudo add-apt-repository -y ppa:ondrej/mysql-5.7
sudo apt-get update
sudo apt-get install -y re2c libpcre3-dev gcc make


#
# Install Git and Tools
#
echo -e "----------------------------------------"
echo "VAGRANT ==> Git"
apt-get install -y git  > /dev/null

echo -e "----------------------------------------"
echo "VAGRANT ==> tools (mc, htop, unzip, memcached, curl)"
apt-get install -y mc htop unzip grc gcc make libpcre3 libpcre3-dev lsb-core autoconf > /dev/null


#
# Hostname
#
echo -e "----------------------------------------"
echo "VAGRANT ==> host name"
hostnamectl set-hostname vagrant-php7-vm


#
# Setup locales
#
echo -e "----------------------------------------"
echo "VAGRANT ==> LOCATES"
echo -e "LC_CTYPE=en_US.UTF-8\nLC_ALL=en_US.UTF-8\nLANG=en_US.UTF-8\nLANGUAGE=en_US.UTF-8" | tee -a /etc/environment > /dev/null
locale-gen en_US en_US.UTF-8
dpkg-reconfigure locales

export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

#
# server
#
echo -e "----------------------------------------"
echo "VAGRANT ==> Nginx"
apt-get install -y nginx  > /dev/null


#
# Nginx host
#
echo -e "----------------------------------------"
echo "VAGRANT ==> Setup Nginx"
cd ~
echo 'server {
    listen      80;
    server_name localhost;
    root        /vagrant/www/;
    index       index.php index.html index.htm;
    charset     utf-8;
    sendfile off;

    #access_log /var/log/nginx/host.access.log main;

    location / {
        try_files $uri $uri/ /index.php?_url=$uri&$args;
    }

    location ~ \.php {
        # try_files   $uri =404;
        fastcgi_pass unix:/var/run/php/php7.0-fpm.sock;
        fastcgi_index /index.php;

        include fastcgi_params;
        fastcgi_param APP_ENV dev;

        fastcgi_split_path_info       ^(.+\.php)(/.+)$;
        fastcgi_param PATH_INFO       $fastcgi_path_info;
        fastcgi_param PATH_TRANSLATED $document_root$fastcgi_path_info;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }

    location ~ /\.ht {
        deny all;
    }
}' > nginx_vhost

#
# enable host
#
echo -e "----------------------------------------"
echo "VAGRANT ==> HOST file"
mv nginx_vhost /etc/nginx/sites-available/nginx_vhost > /dev/null
ln -s /etc/nginx/sites-available/nginx_vhost /etc/nginx/sites-enabled/
rm -rf /etc/nginx/sites-available/default
rm -rf /etc/nginx/sites-enabled/default
service nginx restart > /dev/null

#
# php
#
echo -e "----------------------------------------"
echo "VAGRANT ==> PHP 7"
sudo apt-get install -y php7.0-fpm php7.0-cli php7.0-common php7.0-json php7.0-opcache php7.0-mysql php7.0-phpdbg php7.0-mbstring php7.0-gd php7.0-imap php7.0-ldap php7.0-pgsql php7.0-pspell php7.0-recode php7.0-tidy php7.0-dev php7.0-intl php7.0-gd php7.0-curl php7.0-zip php7.0-xml mcrypt memcached

#
# PHP Error
#
echo -e "----------------------------------------"
echo "VAGRANT ==> Setup PHP7"
sudo sed -i 's/short_open_tag = Off/short_open_tag = On/' /etc/php/7.0/fpm/php.ini
sudo sed -i 's/error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT/error_reporting = E_ALL/' /etc/php/7.0/fpm/php.ini
sudo sed -i 's/display_errors = Off/display_errors = On/' /etc/php/7.0/fpm/php.ini
service php7.0-fpm restart



#
# composer
#
echo -e "----------------------------------------"
echo "VAGRANT ==> Composer"
curl -sS https://getcomposer.org/installer | php > /dev/null
mv composer.phar /usr/local/bin/composer



#
# redis
#
echo -e "----------------------------------------"
echo "VAGRANT ==> Redis Server"
apt-get install -y redis-server redis-tools
cp /etc/redis/redis.conf /etc/redis/redis.bkup.conf
sed -i 's/bind 127.0.0.1/bind 0.0.0.0/' /etc/redis/redis.conf


echo -e "----------------------------------------"
echo "VAGRANT ==> PHP Redis Extension"
git clone https://github.com/phpredis/phpredis.git
cd phpredis
git checkout php7
phpize
./configure
make && make install
cd ..
rm -rf phpredis
cd ~/
echo "extension=redis.so" > ~/redis.ini
cp ~/redis.ini /etc/php/7.0/mods-available/redis.ini
ln -s /etc/php/7.0/mods-available/redis.ini /etc/php/7.0/fpm/conf.d/20-redis.ini

echo -e "----------------------------------------"
echo "VAGRANT ==> Restart Redis & PHP"
service redis-server restart
service php7.0-fpm restart



#
# Grant all privilege to root for remote access
#
echo -e "----------------------------------------"
echo "VAGRANT ==> MySQL"
export DEBIAN_FRONTEND=noninteractive
apt-get install debconf-utils -y > /dev/null
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'
apt-get -q install -y mysql-server-5.6 mysql-client-5.6
cp /etc/mysql/my.cnf /etc/mysql/my.bkup.cnf
sed -i 's/bind-address/bind-address = 0.0.0.0#/' /etc/mysql/my.cnf
mysql -u root -proot -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root' WITH GRANT OPTION; FLUSH PRIVILEGES;"
service mysql restart



#
# Zephir
#
echo -e "----------------------------------------"
echo "VAGRANT ==> Clone Zephir lang"
cd ~
sudo git clone https://github.com/phalcon/zephir
cd zephir
sudo ./install -c



echo -e "----------------------------------------"
echo "VAGRANT ==> Clone Phalcon Framework 2.1.x"
cd ~/
sudo git clone https://github.com/phalcon/cphalcon
cd cphalcon/
sudo git checkout 2.1.x
sudo zephir build —backend=ZendEngine3
echo 'extension=phalcon.so' > /etc/php/7.0/mods-available/phalcon.ini
ln -s /etc/php/7.0/mods-available/phalcon.ini /etc/php/7.0/fpm/conf.d/20-phalcon.ini



#
# Reload servers
#
echo -e "----------------------------------------"
echo "VAGRANT ==> Restart Nginx & PHP5-FPM"
sudo service nginx restart
sudo service php7.0-fpm restart


#
# Add user to group
#
echo -e "----------------------------------------"
echo "VAGRANT ==> Finish"
sudo usermod -a -G www-data vagrant
cd ~
echo "# Generated by /usr/bin/select-editor" > /home/vagrant/.selected_editor
echo "SELECTED_EDITOR=\"/usr/bin/mcedit\"" >> /home/vagrant/.selected_editor

echo -e "----------------------------------------"
echo "======  VIRTUAL MACHINE READY       ======="
echo "======  JUST TYPE 'vagrant ssh'     ======="
echo "======  MYSQL USER: root            ======="
echo "======  MYSQL PASSWORD: root        ======="
echo -e "----------------------------------------"
