#!/usr/bin/bash
# Export variables for cron
DISPLAY=:0 xprintidle
XAUTHORITY=/home/timoffmax/.Xauthority
export DISPLAY=:0

# Set params
min_idle_for_end=1*60*1000;		# If your last activity time greatest than this parameter -- your workday will be closed
max_idle_for_start=10*60*1000;		# If your last activity time lowest than this parameter -- your workday will be opened
bitrix_user_id=;			# Your user ID in Bitrix
bitrix_auth_key=;			# Your Bitrix auth key (get it in "applications" -> "web hooks")
path_to_log="/var/log/bitrix_workday.log";

### FUNCTIONS START ###

# Get actual workday state and save it to variable
function refresh_current_status() {
        status=`curl -s "https://bitrix24.live/rest/"$bitrix_user_id"/"$bitrix_auth_key"/timeman.status" | jq -r '.result' | jq -r '.STATUS'`;  
}

# Save string (first argument) to file
function log() {
        datetime=`date +%Y-%m-%d:%H:%M:%S`;
        log_string="[$datetime] $1";
        echo $log_string >> $path_to_log
}

function check_idle() {
	idle=`/usr/bin/xprintidle`;
	log "IDLE: $idle";
}
### FUNCTIONS END ###

### SCRIPT START ###

#Protection against double run
active_processes=`ps aux | grep "workday_controller.sh" | grep -v grep -c`;

if [[ "$active_processes" -gt "3" ]]; then
	log 'Script already running!';
	exit;
fi

# Get idle (in ms) 
check_idle

# Set current workday status
refresh_current_status

case $1 in
	'status')
		echo $status;
		;;
	'open')
		if [[ "$status" != "OPENED" ]]; then			
			while [[ "$idle" -gt "$max_idle_for_start" ]]; do
				# User not active now, check later
				log 'User not active now, check later.';
				sleep 60;
				check_idle
			done

			# Try to open workday
			responce=`curl -s "https://bitrix24.live/rest/"$bitrix_user_id"/"$bitrix_auth_key"/timeman.open"`;
			
			# Check result
			refresh_current_status
			if [[ "$status" != "OPENED" ]]; then
				log 'Workday start failed!';
			else
				log 'Workday opened!';
			fi

		else
			log 'Workday already opened.';
		fi
		;;
	'pause')
		if [[ "$status" != "PAUSED" ]]; then
			# Try to pause workday
			respone=`curl -s "https://bitrix24.live/rest/"$bitrix_user_id"/"$bitrix_auth_key"/timeman.pause"`;

			# Check result
			refresh_current_status
			if [[ "$status" != "PAUSED" ]]; then
				log 'Workday pause failed!';
			else
				log 'Workday paused.';
			fi
		else
			log 'Workday already paused.';
		fi
		;;
	'resume')
                if [[ "$status" != "OPENED" ]]; then
                        # Try to pause workday
                        respone=`curl -s "https://bitrix24.live/rest/"$bitrix_user_id"/"$bitrix_auth_key"/timeman.resume"`;

                        # Check result
                        refresh_current_status
                        if [[ "$status" != "OPENED" ]]; then
                                log 'Workday resume failed!';
                        else
                                log 'Workday resumed.';
                        fi
                else
                        log 'Workday not paused.';
                fi
                echo $responce;
                ;;
	'close')
		if [[ "$status" != "CLOSED" ]]; then
			echo 
			while [[ "$idle" -lt "$min_idle_for_end" ]]; do
				# User active yet, check later
				log "User active yet, check later.";
				sleep 60;
				check_idle
			done
			
			# Set worklog
			date=`date +%Y-%m-%d`;
			if [[ -f /var/log/git/commits/$date ]]; then
				worklog='.';
				#worklog=`cat /var/log/git/commits/$date`;
			else
				worklog="Work report must be here";
			fi
			
			# Try to close workday	
			responce=`curl -s "https://bitrix24.live/rest/"$bitrix_user_id"/"$bitrix_auth_key"/timeman.close?report='$worklog'"`;

			# Check result
			refresh_current_status
			if [[ "$status" != "CLOSED" ]]; then
				log 'Workday closing failed!';
			else
				log 'Workday closed';
			fi
		else
			log 'Workday already closed.';
		fi 
		;;
	*)
		echo "Unknown argument $1.";
esac
