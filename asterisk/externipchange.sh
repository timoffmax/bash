#!/bin/bash

externip=`wget -qO - icanhazip.com --timeout 10 --tries 1 | grep -P "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}"`
current_ip=`grep "^.*externalip"  /etc/hosts | cut -d " " -f 1 | grep -P "^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$"`

case "$externip" in
        "$current_ip")
        #Don't need changes
        echo "`date +"%Y-%m-%d %H:%M:%S"` [INFO] Nothing to do. IPs are identical." >> /var/log/asterisk/change_ip.log
	echo $externip
        ;;
        '')
        #Something wrong, we don't get IP from icanhazip.com
        echo "`date +"%Y-%m-%d %H:%M:%S"` [ERROR] Something wrong, we don't get IP from icanhazip.com. IP will not change." >> /var/log/asterisk/change_ip.log
        ;;
        *)
        echo "`date +"%Y-%m-%d %H:%M:%S"` [OK] We got another IP from icanhazip.com. The current IP $current_ip has been replaced on the new IP $externip" >> /var/log/asterisk/change_ip.log
        sed -i -e "s/.*externalip/$externip externalip/" /etc/hosts
        /usr/sbin/asterisk -rx "sip reload"
        ;;
esac

exit 0
