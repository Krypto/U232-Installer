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
STARTPHP5FPM='service php5-fpm restart'
STARTNGINX='service nginx restart'

clear
GREEN="\033[00;32m"
RED="\033[00;31m"
CLEAR="\033[00m"

######CHECK MEMCACHED######
SERVICE='memcached'
if  ps ax | grep -v grep | grep $SERVICE > /dev/null
then
	echo -e "${GREEN}$SERVICE service running, everything is fine"
else
	echo -e "${RED}$SERVICE is not running, restarting $SERVICE"
	chkmem=`ps ax | grep -v grep | grep -c memcached`
	if [ $chkmem -le 0 ]
	then
		$STARTMEMCACHED
		if ps ax | grep -v grep | grep $SERVICE >/dev/null
		then
			echo -e "${GREEN}$SERVICE service is now restarted, everything is fine"
		fi
	fi
fi

#####CHECK PHP5-FPM###########
SERVICE='php5-fpm'

if ps ax | grep -v grep | grep php-fpm > /dev/null
then
	echo -e "${GREEN}$SERVICE service running, everything is fine"
else
	echo -e "${RED}$SERVICE is not running, restarting $SERVICE"
	checkphpfpm=`ps ax | grep -v grep | grep -c php-fpm`
	if [ $checkphpfpm -le 0 ]
	then
		$STARTPHP5FPM
		if ps ax | grep -v grep | grep php-fpm > /dev/null
		then
			echo -e "${GREEN}$SERVICE service is now restarted, everything is fine"
		fi
	fi
fi

#####CHECK NGINX###########
SERVICE='nginx'

if ps ax | grep -v grep | grep $SERVICE > /dev/null
then
	echo -e "${GREEN}$SERVICE service running, everything is fine"
else
	echo -e "${RED}$SERVICE is not running, restarting $SERVICE"
	checknginx=`ps ax | grep -v grep | grep -c nginx`
	if [ $checknginx -le 0 ]
	then
		$STARTNGINX
		if ps ax | grep -v grep | grep $SERVICE > /dev/null
		then
			echo -e "${GREEN}$SERVICE service is now restarted, everything is fine"
		fi
	fi
fi

######CHECK XBT##############
SERVICE='xbt_tracker'
if  ps ax | grep -v grep | grep $SERVICE > /dev/null
then
	echo -e "${GREEN}$SERVICE service running, everything is fine"
else
	echo -e "${RED}$SERVICE is not running, restarting $SERVICE"
	checkxbt=`ps ax | grep -v grep | grep -c xbt_tracker`
	if [ $checkxbt -le 0 ]
	then
		cd /root/xbt/Tracker
		$STARTXBT
		if ps ax | grep -v grep | grep $SERVICE >/dev/null
		then
			echo -e "${GREEN}$SERVICE service is now restarted, everything is fine"
		fi
	fi
fi

echo -e "$CLEAR"
