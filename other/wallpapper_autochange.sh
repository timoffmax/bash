#!/usr/bin/bash
DISPLAY=:0.0
timeout=$1

if [ -z $timeout ] ;then
	timeout=600
fi

path=/root/Desktop/Wallpappers

while [ 1 ] ;do
	file=`ls /root/Desktop/Wallpappers/ | shuf -n1`;
	/usr/bin/gsettings set org.gnome.desktop.background picture-uri file:///$path/$file
	echo "$path/$file" >> /var/log/wallpapper_autochange.log
	sleep $timeout
done;
