#!/usr/bin/env bash

if [[ $EUID -ne 0 && whoami != $SUDO_USER ]]; then
	export script=`basename $0`
	echo
	echo -e "\033[1;31mYou must run this script as a user using 
	sudo ./${script}\033[0m" 1>&2
	echo
	exit
fi

STARTXBT='./xbt_tracker'
STARTMEMCACHED='service memcached restart'
STARTPHPFPM='service php5-fpm stop;service php5-fpm stop'
STARTNGINX='service nginx restart'
UPDATEALL='apt-get -yqq update'

clear
read -p "This script uses color by default.
Enter N or n to not use color in the messages.
Any other key to use color.

" -n 1 -r

if [[ $REPLY =~ ^[Nn]$ ]]
then
	YELLOW=""
	RED=""
	CLEAR=""
else
	YELLOW="\033[00;33m"
	RED="\033[00;31m"
	CLEAR="\033[00m"
fi
clear

echo -e "${YELLOW}

|--------------------------------------------------------------------------|
| https://github.com/Bigjoos/ |
|--------------------------------------------------------------------------|
| Licence Info: GPL |
|--------------------------------------------------------------------------|
| Copyright (C) 2010 U-232 V4 |
|--------------------------------------------------------------------------|
| A bittorrent tracker source based on TBDev.net/tbsource/bytemonsoon. |
|--------------------------------------------------------------------------|
| Project Leaders: Mindless,putyn. |
|--------------------------------------------------------------------------|
| Original Script by swizzles                    |
|--------------------------------------------------------------------------|

We are about to install all the basics that you require to get v4 to work.
I am assuming you have at least a basic understanding of servers!!!!!!!!!!!

All that is needed for this script to WORK is a base server install.

This has been written and tested for Ubuntu 14.04 DEDICATED SERVERS. It will
work providing you follow all the instructions.

1. This script will install U-232-V4 from 
   here >> https://github.com/Bigjoos/U-232-V4/archive/master.zip.
2. It will unzip it into your www folder.
3. It will install nginx, percona, php, memcached, opcache and finally but not
   least xbt.
4. Dont worry if during this process it says nothing to do, this normally
   indicates you already have the packages installed.

This has been made as easy as possible with very little interaction from you

ENTER Y or y to continue:
$CLEAR" 
read -p "
" -n 1 -r

if [[ $REPLY =~ ^[Yy]$ ]]
then
clear
echo -e "${YELLOW}We will need to create a MySQL user and database for U232.
Please enter a username to be created.$CLEAR"
read NAME
if [[ $NAME == "" ]]; then
	USERNAME="admin"
else
	USERNAME=$NAME
fi
echo -e "${YELLOW}We need to give \"$USERNAME\" a password.
Please enter a password.$CLEAR"
read -s PW
if [[ $PW == "" ]]; then
	PASS="admin"
else
	PASS=$PW
fi
echo -e "${YELLOW}Please enter the database name to be created.$CLEAR"
read DB
if [[ $DB == "" ]]; then
	DBNAME="admin"
else
	DBNAME=$DB
fi
clear

echo -e "${YELLOW}Updating your system before we begin.$CLEAR"
sleep 5
$UPDATEALL
apt-get -yqq upgrade
updatedb
clear

echo -e "${YELLOW}We will install Percona XtraDB Server first, if it is not already installed.\n$CLEAR"
sleep 5
apt-get install -yqq software-properties-common
gpg --keyserver  hkp://keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A
gpg -a --export CD2EFD2A | apt-key add -
sed -i 's/deb http:\/\/ftp.osuosl.org/#deb http:\/\/ftp.osuosl.org/' /etc/apt/sources.list
sed -i 's/deb-src http:\/\/ftp.osuosl.org/#deb-src http:\/\/ftp.osuosl.org/' /etc/apt/sources.list
sed -i 's/#deb http:\/\/repo.percona.com/deb http:\/\/repo.percona.com/' /etc/apt/sources.list
sed -i 's/#deb-src http:\/\/repo.percona.com/deb-src http:\/\/repo.percona.com/' /etc/apt/sources.list
if ! grep -q '#Percona' "/etc/apt/sources.list" ; then
	echo "" | tee -a /etc/apt/sources.list
	echo "#Percona" >> /etc/apt/sources.list
	echo "deb http://repo.percona.com/apt quantal main" >>/etc/apt/sources.list
	echo "deb-src http://repo.percona.com/apt quantal main" >> /etc/apt/sources.list
fi
# set to non interactive
export DEBIAN_FRONTEND=noninteractive

$UPDATEALL
mkdir -p /etc/mysql
wget --no-check-certificate https://raw2.github.com/jonnyboy/U232-Installer/master/config/my.cnf -O /etc/mysql/my.cnf
apt-get install -yqq percona-server-client-5.6 percona-server-server-5.6 percona-toolkit
clear

echo -e "${YELLOW}If this is the first time installing Percona or MySQL, then your
MySQL password for root is currently empty, meaning no password has been set."
echo -e "Adding Percona functions: to install, press enter."
echo -e "${RED}To NOT install, type anything for the password and press enter.\n\n$CLEAR"
echo -e "${YELLOW}mysql -uroot -p -e \"CREATE FUNCTION fnv1a_64 RETURNS INTEGER SONAME 'libfnv1a_udf.so'\"$CLEAR"
mysql -uroot -p -e "CREATE FUNCTION fnv1a_64 RETURNS INTEGER SONAME 'libfnv1a_udf.so'"
echo -e "${YELLOW}mysql -uroot -p -e \"CREATE FUNCTION fnv_64 RETURNS INTEGER SONAME 'libfnv_udf.so'\"$CLEAR"
mysql -uroot -p -e "CREATE FUNCTION fnv_64 RETURNS INTEGER SONAME 'libfnv_udf.so'"
echo -e "${YELLOW}mysql -uroot -p -e \"CREATE FUNCTION murmur_hash RETURNS INTEGER SONAME 'libmurmur_udf.so'\"$CLEAR"
mysql -uroot -p -e "CREATE FUNCTION murmur_hash RETURNS INTEGER SONAME 'libmurmur_udf.so'"

clear
echo -e "${YELLOW}REMEMBER THE PASSWORD YOU INPUT HERE AS YOU WILL NEED IT FOR YOUR CONF FILES LATER!"
echo -e "IT IS NOT RECOMMENDED TO LEAVE THE PASSWORD BLANK!$CLEAR"
mysql -uroot -e "CREATE USER \"$USERNAME\"@'localhost' IDENTIFIED BY \"$PASS\";CREATE DATABASE $DBNAME;GRANT ALL PRIVILEGES ON $DBNAME . * TO $USERNAME@localhost;FLUSH PRIVILEGES;"
mysql_secure_installation
sleep 1
clear

echo -e "${YELLOW}Nginx needs to have the ip or FQDN of the server you are installing to.
If your installing remotely, localhost will not work in most cases.
Enter the ip or FQDN of this server.
Detected IP's and hostname:$CLEAR"
hostname
/sbin/ifconfig | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}'
netcat icanhazip.com 80 <<< $'GET / HTTP/1.0\nHost: icanhazip.com\n\n' | tail -n1

echo
read IPADDY

add-apt-repository -y ppa:nginx/stable
$UPDATEALL
apt-get install -yqq nginx-extras apache2-utils
mkdir -p /var/log/nginx
chmod 755 /var/log/nginx
wget --no-check-certificate https://raw.githubusercontent.com/jonnyboy/U232-Installer/master/config/tracker -O /etc/nginx/sites-available/tracker
wget --no-check-certificate https://raw.githubusercontent.com/jonnyboy/U232-Installer/master/config/nginx.conf -O /etc/nginx/nginx.conf
CORES=`cat /proc/cpuinfo | grep processor | wc -l`
sed -i "s/^worker_processes.*$/worker_processes $CORES;/" /etc/nginx/nginx.conf
sed -i "s/localhost/$IPADDY/" /etc/nginx/sites-available/tracker
if ! grep -q 'fastcgi_index index.php;' "/etc/nginx/fastcgi_params" ; then
	echo "" >> /etc/nginx/fastcgi_params
	echo "fastcgi_index index.php;" | tee -a /etc/nginx/fastcgi_params
fi
if ! grep -q 'fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;' "/etc/nginx/fastcgi_params" ; then
	echo "fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;" | tee -a /etc/nginx/fastcgi_params
fi

if [ -f "/etc/nginx/sites-enabled/default" ]; then
	unlink /etc/nginx/sites-enabled/default
fi
ln -sf /etc/nginx/sites-available/tracker /etc/nginx/sites-enabled/tracker

clear
echo -e "${YELLOW}Installing PHP, PHP-FPM.$CLEAR"
apt-get install -yqq php5-fpm
apt-get install -yqq php5 php5-dev php-pear php5-gd php5-curl php5-memcache php5-json php5-xdebug php5-mysqlnd php5-idn php5-imagick php5-imap php5-mcrypt php5-memcache php5-mhash php5-ming php5-ps php5-pspell php5-recode php5-snmp php5-sqlite php5-tidy php5-xmlrpc php5-xsl php5-cgi php5-geoip memcached
apt-get -yqq install libpcre3 libpcre3-dev unzip
apt-get -yqq install cmake g++ libboost-date-time-dev libboost-dev libboost-filesystem-dev libboost-program-options-dev libboost-regex-dev libboost-serialization-dev libmysqlclient15-dev make subversion zlib1g-dev
sed -i 's/max_execution_time.*$/max_execution_time = 180/' /etc/php5/cli/php.ini
sed -i 's/max_execution_time.*$/max_execution_time = 180/' /etc/php5/fpm/php.ini
sed -i 's/memory_limit.*$/memory_limit = 100M/' /etc/php5/cli/php.ini
sed -i 's/memory_limit.*$/memory_limit = -100M/' /etc/php5/fpm/php.ini
sed -i 's/[;?]date.timezone.*$/date.timezone = America\/New_York/' /etc/php5/cli/php.ini
sed -i 's/[;?]date.timezone.*$/date.timezone = America\/New_York/' /etc/php5/fpm/php.ini
sed -i 's/[;?]cgi.fix_pathinfo.*$/cgi.fix_pathinfo = 0/' /etc/php5/fpm/php.ini
sed -i 's/[;?]cgi.fix_pathinfo.*$/cgi.fix_pathinfo = 0/' /etc/php5/cli/php.ini
sed -i 's/short_open_tag.*$/short_open_tag = Off/' /etc/php5/fpm/php.ini
sed -i 's/short_open_tag.*$/short_open_tag = Off/' /etc/php5/cli/php.ini
sed -i 's/display_errors.*$/display_errors = On/' /etc/php5/fpm/php.ini
sed -i 's/display_errors.*$/display_errors = On/' /etc/php5/cli/php.ini
sed -i 's/display_startup_errors.*$/display_startup_errors = On/' /etc/php5/fpm/php.ini
sed -i 's/display_startup_errors.*$/display_startup_errors = On/' /etc/php5/cli/php.ini

clear
echo -e "${YELLOW}And now opcache$CLEAR"
sleep 2
pecl install zendopcache-7.0.2
echo 'zend_extension=/usr/lib/php5/20100525/opcache.so
opcache.memory_consumption=128
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=4000
opcache.revalidate_freq=60
opcache.fast_shutdown=1
opcache.enable_cli=1' > /etc/php5/mods-available/opcache.ini

sleep 2
clear

unset DEBIAN_FRONTEND
dpkg-reconfigure tzdata
echo -e "${YELLOW}PHP timezone was set to New York, you may wish to change that.$CLEAR"

#get user home folder
export USER_HOME=$(getent passwd $SUDO_USER | cut -d: -f6)

cp /etc/nanorc $USER_HOME/.nanorc
sed -i -e 's/^# include/include/' $USER_HOME/.nanorc
sed -i -e 's/^# set tabsize 8/set tabsize 4/' $USER_HOME/.nanorc
sed -i -e 's/^# set historylog/set historylog/' $USER_HOME/.nanorc
ln -sf $USER_HOME/.nanorc /root/

echo -e "${YELLOW}Configuring OpenNTPD$CLEAR"
ntpdate pool.ntp.org
apt-get install -yqq openntpd
mv /etc/openntpd/ntpd.conf /etc/openntpd/ntpd.conf.orig
echo 'server 0.us.pool.ntp.org' >> /etc/openntpd/ntpd.conf
echo 'server 1.us.pool.ntp.org' >> /etc/openntpd/ntpd.conf
echo 'server 2.us.pool.ntp.org' >> /etc/openntpd/ntpd.conf
echo 'server 3.us.pool.ntp.org' >> /etc/openntpd/ntpd.conf
service openntpd restart
sleep 5
clear

echo -e "${YELLOW}Now we download the Site Source:
and do all the unzips and copy site to /var/www,
then we do the stuff like chmods etc.$CLEAR"
sleep 3

cd $USER_HOME
wget https://github.com/Bigjoos/U-232-V4/archive/master.zip -O master.zip
unzip -oqq master.zip
cd U-232-V4-master
tar -zxf pic.tar.gz
tar -zxf GeoIP.tar.gz
tar -zxf javairc.tar.gz
cd /var
mkdir -p bucket/avatar
cd bucket
cp $USER_HOME/U-232-V4-master/torrents/.htaccess .
cp $USER_HOME/U-232-V4-master/torrents/index.* .
cd avatar
cp $USER_HOME/U-232-V4-master/torrents/.htaccess .
cp $USER_HOME/U-232-V4-master/torrents/index.* .
cd $USER_HOME
chmod -R 777 /var/bucket
mkdir -p /var/www
cp -ar $USER_HOME/U-232-V4-master/* /var/www
chmod -R 777 /var/www/cache
chmod 777 /var/www/dir_list
chmod 777 /var/www/uploads
chmod 777 /var/www/uploadsub
chmod 777 /var/www/imdb
chmod 777 /var/www/imdb/cache
chmod 777 /var/www/imdb/images
chmod 777 /var/www/include
chmod 777 /var/www/include/backup
chmod 777 /var/www/include/settings
echo > /var/www/include/settings/settings.txt
chmod 777 /var/www/include/settings/settings.txt
chmod 777 /var/www/install
chmod 777 /var/www/install/extra
chmod 777 /var/www/install/extra/config.xbtsample.php
chmod 777 /var/www/install/extra/ann_config.xbtsample.php
chmod 777 /var/www/install/extra/config.phpsample.php
chmod 777 /var/www/install/extra/ann_config.phpsample.php
mkdir /var/www/logs
chmod 777 /var/www/logs
chmod 777 /var/www/torrents
clear

echo -e "${YELLOW}Now the biggy, to install xbt so your site can fly...lol
Time to grab the goodies and put them in root, away from prying eyes. (REMEMBER YOU CAN PUT THIS ANYWHERE YOU WANT)$CLEAR"
sleep 2
cd /root/
svn co http://xbt.googlecode.com/svn/trunk/xbt/misc xbt/misc
svn co http://xbt.googlecode.com/svn/trunk/xbt/Tracker xbt/Tracker
clear

echo -e "${YELLOW}Now for xbt. We will now copy the custom server.cpp and server.h to the TRACKER folder$CLEAR"
sleep 2
cp -R /var/www/XBT/{server.cpp,server.h,xbt_tracker.conf}  /root/xbt/Tracker/
clear

echo -e "${YELLOW}Now to install the daemon. Be patient as this could take a few minutes$CLEAR"
sleep 2
cd /root/xbt/Tracker/
./make.sh
clear

echo -e "${YELLOW}RIGHT - now we add your mysql connect details to xbt_tracker.conf$CLEAR"
sed -i "s/^mysql_user.*$/mysql_user=$USERNAME/" /root/xbt/Tracker/xbt_tracker.conf
sed -i "s/^mysql_password.*$/mysql_password=$PASS/" /root/xbt/Tracker/xbt_tracker.conf
sed -i "s/^mysql_database.*$/mysql_database=$DBNAME/" /root/xbt/Tracker/xbt_tracker.conf

cd /root/xbt/Tracker
./xbt_tracker
sleep 3
clear

wget --no-check-certificate https://raw2.github.com/jonnyboy/U232-Installer/master/config/check_status.sh -O $USER_HOME/check_status.sh
chmod a+x $USER_HOME/check_status.sh

cd /var/www/
wget http://downloads.sourceforge.net/project/phpmyadmin/phpMyAdmin/4.2.9/phpMyAdmin-4.2.9-all-languages.tar.gz
tar -xf phpMyAdmin-4.2.9-all-languages.tar.gz
mv phpMyAdmin-4.2.9-all-languages phpmyadmin
rm phpMyAdmin-4.2.9-all-languages.tar.gz
cd phpmyadmin
mkdir -p config
chmod o+rw config

#set correct permissions
chown -R $SUDO_USER:$SUDO_USER $USER_HOME
chown -R www-data:www-data /var/www

php5enmod mcrypt
$STARTPHPFPM
$STARTNGINX
clear

echo -e "${YELLOW}phpMyAdmin has been installed, but needs to be configured.
To complete it's installation, point your browser to http://${IPADDY}/phpmyadmin/setup/
and follow the instructions.

But, for now you need to point your browser to http://${IPADDY}/install/
and complete the site installation process.

Then, add yourself to the site by going to http://${IPADDY} and using the 'Join us' button to create a new user.
Login using the user you just created. Then, create a second user with the name 'System'.
Ensure it's userid2 so you dont need to alter the autoshout function on include.

Sysop is added automatically to the array in cache/staff_settings.php and cache/staff_setting2.php.
Staff is automatically added to the same 2 files, but you have to make sure the member is offline before you promote them.

$USER_HOME/check_status.sh was added to quickly check the status of the required services and restart as necessary.

Once you have completed the above steps:"
read -p "
Pressy any key to continue:
" -n 1 -r

echo -e "$CLEAR"
mv /var/www/install /var/www/installold
echo -e "${YELLOW}/var/www/install has been moved to /var/www/installold.$CLEAR"
$USER_HOME/check_status.sh

fi

