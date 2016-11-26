#!/bin/bash

trunks_quantity=$#

	COUNTER=1
        while [ $COUNTER -le $trunks_quantity ]; do
                
		#Good state if trunk has registration string
		good_state='Registered';
                
		trunks_status[$COUNTER]=`/usr/bin/sudo /usr/sbin/asterisk -rx 'sip show registry' | grep -P "\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}" | grep ${!COUNTER}`
		trunks_status[$COUNTER]=`echo ${trunks_status[$COUNTER]} | cut -d " " -f 3,5,7,8,10`
		
		current_status=`echo ${trunks_status[$COUNTER]} | cut -d " " -f 2`
		
		#If array element is empty then trunk hasn`t registration string
		if [ -z "${trunks_status[$COUNTER]}" ] ;then
 			
			#Good state if trunk hasn`t registration string
			good_state='OK';
			
			#Determine trunk status
			trunks_status[$COUNTER]=`/usr/bin/sudo /usr/sbin/asterisk -rx 'sip show peers' | grep ${!COUNTER}`
	
			if [ -n "${trunks_status[$COUNTER]}" ] ;then
				#Trunk exist. Go!
				peer_name=`echo ${trunks_status[$COUNTER]} | cut -d " " -f 1`
				peer_ip=`echo ${trunks_status[$COUNTER]} | cut -d " " -f 2`
				current_status=`echo ${trunks_status[$COUNTER]} | egrep -oi "OK|UNREACHABLE|UNKNOWN"`
				trunks_status[$COUNTER]=`echo $peer_name $peer_ip $current_status`
			else
				#Trunk not exist. Destroy array element.
                                unset trunks_status[$COUNTER]
			fi

		fi

                case $current_status in
                        $good_state)
				#All ok with this trunk. Destroy array element.
                                unset trunks_status[$COUNTER]
                        ;;
                        *)
				#We have some troubles with this trunk. Information was saved in array.
			;;
                esac
		
		#Next iteration
                let COUNTER=COUNTER+1
         done

	#Print status if we have trunks with problem status	
	if [[ ${#trunks_status[@]} -ne 0 ]] ; then
        	echo ""
		i=1
        	while [ $i -le $COUNTER ]  ;do
			if [ -n "${trunks_status[$i]}" ] ;then
				echo "| ${trunks_status[$i]} |"
			fi
                let i=i+1
        done
	else
        	echo 'OK'
	fi
