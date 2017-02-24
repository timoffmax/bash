######START FUNCTION SECTOR#####

app_install() {
        case $dist_name in
                "debian")
                        apt-get install $app_name
                        ;;
                "centos")
                        yum install $app_name
                        ;;
                *)
                        echo "[X] Your OS is not identified! $app_name is not installed!"; echo;
        esac
}

installation_check() {

        check=$(which $app_name | grep -o "/usr/sbin/$app_name");

        case $dist_name in
                "debian")
                        check_debian=$(dpkg --status $app_name | grep -o "ok installed")
                        ;;
                "centos")
                        check_centos=$(yum list | egrep -o "^$app_name\>[^-]" | head -1 | grep -o "$app_name")
                        ;;
                *)
                        echo "Your OS is not identified! $app_name is not installed!"; echo;
        esac

        if [[ "$check" == "/usr/sbin/$1" || "$check_debian" == "ok installed" || "$check_centos" == "$app_name" ]] ;then

                status="already_install"

        elif [ "$2" = "install_anyway" ] ;then

                app_install $dist_name app_name
                installation_check $app_name

                if [ "$status" = "already_install" ] ;then
                        status="installation_successfully"
                else
                        status="installation_error"
                fi

        fi

}

print_status() {

 case $status in
        "already_install")
                echo; echo "[!] $app_name is already install! Setting up $app_name..."; echo
                ;;
        "installation_successfully")
                echo; echo "[!] $app_name installed successfully! Setting up $app_name..."; echo
                ;;
        "installation_error")
                echo; echo "[!] $app_name installation failed! Please, installing $app_name manually."; echo
                ;;
 esac

}

logrotate_setting_up() {
        touch /etc/logrotate.d/asterisk

        echo "/var/log/asterisk/full {" > /etc/logrotate.d/asterisk
        echo "                        daily" >> /etc/logrotate.d/asterisk
        echo "                        size 500M" >> /etc/logrotate.d/asterisk
        echo "                        rotate 3" >> /etc/logrotate.d/asterisk
        echo "                        missingok" >> /etc/logrotate.d/asterisk
        echo "                        compress" >> /etc/logrotate.d/asterisk
        echo "                        nocreate" >> /etc/logrotate.d/asterisk
        echo "                        notifempty" >> /etc/logrotate.d/asterisk
        echo "                        sharedscripts" >> /etc/logrotate.d/asterisk
        echo "                        postrotate" >> /etc/logrotate.d/asterisk
        echo "                         /usr/sbin/asterisk -rx 'logger reload' > /dev/null 2> /dev/null " >> /etc/logrotate.d/asterisk
        echo "                        endscript" >> /etc/logrotate.d/asterisk
        echo "}" >> /etc/logrotate.d/asterisk

        case $dist_name in
                "debian")
                        cron="/var/spool/cron/crontabs/$(echo $USER)"
                        ;;
                "centos")
                        cron="/var/spool/cron/$(echo $USER)"
                        ;;
                *)
                        echo "[X] Your OS is not identified! $app_name is not installed!"; echo;
        esac

        if [[ -z "$(cat $cron | grep 'logrotate' | grep -v '#')" ]]; then
              echo "* * * * 3 /usr/sbin/logrotate /etc/logrotate.conf" >> $cron
              /etc/init.d/cron restart
        fi


        logrotate -f /etc/logrotate.conf

}

ntp_setting_up() {
         sed -i 's/^server 0.*org/server 0.ua.pool.ntp.org/' /etc/ntp.conf
         sed -i 's/^server 1.*org/server 1.ua.pool.ntp.org/' /etc/ntp.conf
         sed -i 's/^server 2.*org/server 2.ua.pool.ntp.org/' /etc/ntp.conf
         sed -i 's/^server 3.*org/server 3.ua.pool.ntp.org/' /etc/ntp.conf

         chkconfig ntpd on
}

dmesg_setting_up() {
        user=$(whoami)
        if [[ "$user" = "root" ]]; then
            echo Y | tee /sys/module/printk/parameters/time > /dev/null
        else
            echo Y | sudo tee /sys/module/printk/parameters/time > /dev/null
        fi

        echo "hello world" > /dev/kmsg
        wget --timeout 10 --tries 1 http://nagg.ru/wp-content/uploads/2013/01/dmesg.pl --no-check-certificate > /dev/null
        chmod +x dmesg.pl
}

history_setting_up() {
        history_check=$(cat .bashrc | grep -P 'For history|HISTTIMEFORMAT' | head -1 | grep '' -c)

        if [[ "$history_check" -eq 1 ]]; then
                history_installation_status="OK"
                echo; echo "[OK] history already setting up!"
        else
                echo "" >> .bashrc
                echo "# For history" >> .bashrc
                echo "HISTTIMEFORMAT=\"%h/%d - %H:%M:%S \"" >> .bashrc
                echo "export HISTSIZE=10000" >> .bashrc
                echo "export HISTFILESIZE=10000" >> .bashrc
                echo "shopt -s histappend" >> .bashrc
                echo "PROMPT_COMMAND='history -a'" >> .bashrc
                source .bashrc
        fi
}

ntp_check() {

        case $dist_name in
                "debian")
                        /etc/init.d/ntp stop
                                                sync_state=$(ntpdate-debian 0.ua.pool.ntp.org | grep -o "offset")
                                                /etc/init.d/ntp start
                                                update-rc.d ntp defaults
                        ;;
                "centos")
                        /etc/init.d/ntpd stop
                                                sync_state=$(ntpdate 0.ua.pool.ntp.org | grep -o "offset")
                                                /etc/init.d/ntpd start
                        ;;
                *)
                        echo "[X] Your OS is not identified! $app_name is not configured!"; echo;
    esac

        if [[ "$sync_state" == "offset" ]]; then
                echo "[OK] ntp synchronization is work!"; echo;
                ntp_installation_status="OK"
        else
                echo "[X] ntp synchronization error!"; echo;
                ntp_installation_status="error"
        fi

}

dmesg_check() {

        dmesg_check=$(./dmesg.pl | grep -o "hello world")

        if [[ -n "$dmesg_check" ]]; then
                dmesg_installation_status="OK"
                echo; echo "[OK] dmesg setting up successfully!"; echo
        else
                dmesg_installation_status="error"
                echo; echo "[X] dmesg setting up error!"; echo
        fi
}

history_check() {
        history_check=$(cat .bashrc | grep 'For history' | head -1 | grep '' -c)

        if [[ -n "$history_check" ]]; then
                history_installation_status="OK"
                echo; echo "[OK] history setting up successfully!"
                echo "[!] Please relogin to see the changes in the history!"; echo
        else
                history_installation_status="error"
                echo; echo "[X] history setting up error!"; echo
        fi
}

logrotate_check() {
        logrotate_check=$(crontab -l | grep -o "logrotate" | head -1)

        if [[ -n "$logrotate_check" ]]; then
                logrotate_installation_status="OK"
                echo "[OK] logrotate setting up successfully!"; echo
        else
                logrotate_installation_status="error"
                echo; echo "[X] history setting up error!"; echo
        fi
}

detect_system() {

os=$(uname -s)
dist_name='unknown'
dist_version='unknown'

case "${os}" in
    'Linux')
        lsb_release_path=$(which lsb_release 2> /dev/null)
        if [ "${lsb_release_path}x" != "x" ]; then
            dist_name=$(${lsb_release_path} -i | cut -d ':' -f2 )
            dist_version=$(${lsb_release_path} -r | cut -d ':' -f2 | sed 's/\t *//g')
        else
            if [ -r '/etc/debian_version' ]; then
                if [ -r '/etc/dpkg/origins/ubuntu' ]; then
                    dist_name='ubuntu'
                else
                    dist_name='debian'
                fi
                dist_version=$(cat /etc/debian_version | sed s/.*\///)
            elif [ -r '/etc/mandrake-release' ]; then
                dist_name=$(cat /etc/mandrake-release | sed s/.*\(// | sed s/\)//)
                dist_version=$(cat /etc/mandrake-release | sed 's/.*release\ //' | sed 's/\ .*//')
            elif [ -r '/etc/redhat-release' ]; then
                if [ -r '/etc/asplinux-release' ]; then
                    dist_name='asplinux'
                    dist_version=$(cat /etc/asplinux-release | sed 's/.*release\ //' | sed 's/\ .*//' )
                elif [ -r '/etc/altlinux-release' ]; then
                    dist_name='altlinux'
                    dist_version=$(cat /etc/altlinux-release | sed 's/.*Linux\ //' | sed 's/\ .*//')
                else
                    if [ "$(cat /etc/redhat-release | grep -i 'Red Hat Enterprise')x" != "x" ]; then
                        dist_name='rhel'
                    else
                        dist_name=$(cat /etc/redhat-release | cut -d ' ' -f1)
                    fi
                    dist_version=$(cat /etc/redhat-release | sed 's/.*release\ //' | sed 's/\ .*//' )
                fi
            elif [ -r '/etc/arch-release' ]; then
                dist_name='archlinux'
                dist_version=$(cat /etc/arch-release)
            elif [ -r '/etc/SuSe-release' ]; then
                dist_name='opensuse'
                dist_version=$(cat /etc/SuSe-release | grep 'VERSION' | sed 's/.*=\ //')
            elif [ -r '/etc/sles-release' ]; then
                dist_name='sles'
                dist_version=$(cat /etc/SuSe-release | grep 'VERSION' | sed 's/.*=\ //')
            elif [ -r '/etc/slackware-version' ]; then
                if [ -r '/etc/zenwalk-version' ]; then
                    dist_name='zenwalk'
                    dist_version=$(cat /etc/zenwalk-version)
                elif [ -r '/etc/slax-version' ]; then
                    dist_name='slax'
                    dist_version=$(cat /etc/slax-version | cut -d ' ' -f2)
                else
                    dist_name=$(cat /etc/slackware-version | cut -d ' ' -f1)
                    dist_version=$(cat /etc/slackware-version | cut -d ' ' -f2)
                fi
            elif [ -r /etc/puppyversion ]; then
                dist_name='puppy'
                dist_version=$(cat /etc/puppyversion)
            fi
        fi
    ;;
    'OpenBSD'|'NetBSD'|'FreeBSD'|'SunOS')
        dist_name=$os
        if [ "$dist_name" = "SunOS" ]; then
            dist_name='solaris'
        fi
        dist_version=$(uname -r | sed 's/-.*//')
    ;;
    'Darwin')
        dist_name='macos'
        dist_version=$(sw_vers -productVersion)
    ;;
esac

dist_name=$(echo $dist_name | tr '[:upper:]' '[:lower:]')
echo "You operation system is $dist_name-$dist_version."; echo;
}

run() {
    if [[ $@ != '' ]]; then
        i=0
        while [ $# -gt 0 ]; do
            i=$[i+1]
            echo "--------------------------------------------------"
            echo "Stage $i: Trying to install and configure $1."
            echo "--------------------------------------------------"; echo;
            case $1 in
                'dmesg')
                    dmesg_setting_up
                    dmesg_check
                    ;;
                'history')
                    history_setting_up
                    history_check
                    ;;
                'ntp')
                    app_name="ntp"

                    installation_check $app_name install_anyway
                    print_status $status

                    if [ "$dist_name" = "debian" ]; then
                            app_name="ntpdate"
                            installation_check $app_name install_anyway
                            print_status $status
                    fi

                    case $status in
                            "installation_successfully")
                                    ntp_setting_up
                                    ntp_check
                                    ;;
                            "already_install")
                                    ntp_check
                                    ;;
                            *)
                                    echo "[X] $app_name not installed! Configure will fail."; echo
                                    ntp_installation_status="error";
                                    ;;
                    esac
                    ;;
                'logrotate')
                    installation_check $app_name install_anyway
                    print_status $status

                    case $status in
                            "installation_successfully" | "already_install")
                                    logrotate_setting_up
                                    ;;
                            *)
                                    echo "[X] logrotate not installed! Configure will fail."; echo
                                    logrotate_installation_status="error";
                                    ;;
                    esac

                    logrotate_check
                    ;;
                *)
                    echo "[X] can'n setting up $item! Please, check script params."; echo
                    ;;
            esac
            shift
        done
    else
        run dmesg logrotate ntp history
    fi
    i=$[i+1]
    echo "-----------------------------"
    echo "Stage $i: Summary information."
    echo "-----------------------------"; echo;

    echo "[$dmesg_installation_status] dmesg configuration"
    echo "[$history_installation_status] history configuration"
    echo "[$logrotate_installation_status] logrotate installation"
    echo "[$ntp_installation_status] ntp installation"

    echo; echo
}

######END FUNCTION SECTOR#####
######Stage 0#####
echo "--------------------------------------"
echo "Stage 0: Detect your operation system."
echo "--------------------------------------"; echo;
detect_system

###Run installation with script args
run $*