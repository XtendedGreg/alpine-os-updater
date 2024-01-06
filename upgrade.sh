#!/bin/ash
# Alpine Linux OS Version Updater
# By: XtendedGreg - https://youtube.com/@XtendedGreg
# Github: https://github.com/XtendedGreg/alpine-os-updater
# Based on https://wiki.alpinelinux.org/wiki/Upgrading_Alpine

if [ -e /tmp/upgradeLog ]; then rm /tmp/upgradeLog; fi # Clear log file if it exists

echo "" | tee /tmp/upgradeLog
echo "########### Alpine Linux OS Upgrade Start - Initial Pass #############" | tee -a /tmp/upgradeLog
echo "Upgrade Script by : XtendedGreg [https://youtube.com/@XtendedGreg]" | tee -a /tmp/upgradeLog
echo "Last Update : January 4, 2024" | tee -a /tmp/upgradeLog
echo "Github : https://github.com/XtendedGreg/alpine-os-updater" | tee -a /tmp/upgradeLog
echo "Based on https://wiki.alpinelinux.org/wiki/Upgrading_Alpine" | tee -a /tmp/upgradeLog

while [ $# -gt 0 ]; do
    if [[ $1 == "--"* ]]; then
        v="${1/--/}"
        eval $v=1
        shift
    fi
    shift
done

if [ ! -z $help ]; then
	echo "" | tee -a /tmp/upgradeLog
	echo "Usage: $0 [--CONFIRM_ARCH] [--SKIP_CHECK] [--SKIP_CONFIRM]" | tee -a /tmp/upgradeLog
	echo "" | tee -a /tmp/upgradeLog
	exit 0
fi

echo "Start Date : $(date)" | tee -a /tmp/upgradeLog

. /etc/os-release
. /etc/lbu/lbu.conf

# Get system Arch and Verify against uname and resolve if there is an issue
ARCH=$(cat /etc/apk/arch)
UNAMEARCH=$(uname -a | rev | awk '{print $2}' | rev)
if [[ $UNAMEARCH != $ARCH* ]]; then
	# ARCH Mismatch
 	BESTARCH=$ARCH
 	# Get list of arch types for latest release
  	for arch in $(wget -qO- https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/ | grep -e "^<a href=" | cut -d">" -f2 | cut -d"/" -f1 ); do
   		if [ $(echo $UNAMEARCH | grep $arch | wc -l) -eq 1 ]; then
     			BESTARCH=$arch
			if [[ "$UNAMEARCH" == "$arch" ]]; then
   				# Break on exact match otherwise keep going in case there is a better match
				break
    			fi
   		fi
     	done
      	echo "" | tee -a /tmp/upgradeLog
      	echo -n "NOTICE: Architecture $ARCH does not match uname value of $UNAMEARCH. "
       	if [[ "$ARCH" != "" ]]; then
		echo "You may want to change to $BESTARCH instead for your hardware." | tee -a /tmp/upgradeLog
     	fi
      	echo "WARNING: While your hardware is working with this version of Alpine Linux now for this architecture, the upgraded version may not." | tee -a /tmp/upgradeLog
      	if [ -z $CONFIRM_ARCH ]; then
		while true; do
			echo -n "Do you still want to upgrade to the latest Alpine Linux version(y/n)? [n] " | tee -a /tmp/upgradeLog
			read confirm <&1 # Read from stdout instead of stdin since it would just read next line of script when run through pipe
			echo $confirm >> /tmp/upgradeLog
			if [[ "$confirm" == "y" ]] || [[ "$confirm" == "Y" ]]; then
				echo "User selected to proceed." | tee -a /tmp/upgradeLog
				break
			elif [[ "$confirm" == "n" ]] || [[ "$confirm" == "N" ]] || [[ -z $confirm ]]; then
				echo "User selected No." | tee -a /tmp/upgradeLog
				exit
			else
				echo "Please answer yes (y) or no (n)." | tee -a /tmp/upgradeLog
			fi
		done
	else
		echo "### CONFIRM_ARCH SET" | tee -a /tmp/upgradeLog
	fi
fi

APKCACHE=$(cd -P "/etc/apk/cache" && pwd)
ALPINE_RELEASE=$(cat /media/${LBU_MEDIA}/.alpine-release | awk '{print $1}')
LATEST_RELEASE=$(wget -qO- https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/${ARCH}/latest-releases.yaml | grep version | head -n1 | awk '{print $2}')
COMMUNITY_ENABLED=$(cat /etc/apk/repositories | grep community | grep -v "/edge/" | grep -e "^#http" | wc -l) # Exclude edge repositories

if [ $COMMUNITY_ENABLED -eq 1 ]; then # This is inverted
	APKREPOS_FLAG=""
else
	APKREPOS_FLAG="-c"
fi

echo "" | tee -a /tmp/upgradeLog
echo " ##################### OS UPGRADE DETAILS #####################" | tee -a /tmp/upgradeLog
echo " #                                                            #" | tee -a /tmp/upgradeLog
printf " #       Current Alpine Version : %-27s #\n" $VERSION_ID | tee -a /tmp/upgradeLog
printf " #        Latest Alpine Version : %-27s #\n" $LATEST_RELEASE | tee -a /tmp/upgradeLog
printf " #                    LBU Media : %-27s #\n" $LBU_MEDIA | tee -a /tmp/upgradeLog
printf " #                 Architecture : %-27s #\n" $ARCH | tee -a /tmp/upgradeLog

if [ $COMMUNITY_ENABLED -eq 1 ]; then
	printf " # Community Repository Enabled : %-27s #\n" "No" | tee -a /tmp/upgradeLog
else
	printf " # Community Repository Enabled : %-27s #\n" "Yes" | tee -a /tmp/upgradeLog
fi
echo " #                                                            #" | tee -a /tmp/upgradeLog
echo " ##############################################################" | tee -a /tmp/upgradeLog
echo "" | tee -a /tmp/upgradeLog

# Verify ARCH is currently supported by this script - Raspberry Pi Only right now
if [ $(cat /media/${LBU_MEDIA}/.alpine-release | awk '{print $1}' | grep "alpine-rpi-" | wc -l) -ne 1 ]; then
	echo "Currently this upgrade script only supports Raspberry Pi." | tee -a /tmp/upgradeLog
	exit 0
fi

# Exit if the latest version of Alpine Linux is already installed
if [[ $VERSION_ID == $LATEST_RELEASE ]]; then
	echo "Already the latest version of Alpine Linux. Move along, nothing to see here." | tee -a /tmp/upgradeLog
	exit 0
fi

if [ -z $SKIP_CHECK ]; then
	#### Check Packages to see if there will be any broken dependancies
	mkdir -p /tmp/newRepo/main/${ARCH}
	if [ -e /tmp/newRepo/main/${ARCH}/APKINDEX.tar.gz ]; then rm /tmp/newRepo/main/${ARCH}/APKINDEX.tar.gz; fi
	wget -qP /tmp/newRepo/main/${ARCH} https://dl-cdn.alpinelinux.org/alpine/latest-stable/main/${ARCH}/APKINDEX.tar.gz | tee -a /tmp/upgradeLog
 	if [ ! -e /tmp/newRepo/main/${ARCH}/APKINDEX.tar.gz ]; then
  		echo "Unable to download main repository index for package check.  If you would like to skip this check, use --SKIP_CHECK to skip this function." | tee -a /tmp/upgradeLog
    		exit 1;
      	fi
	echo /tmp/newRepo/main/ > /tmp/repo
	if [ $COMMUNITY_ENABLED -ne 1 ]; then
		mkdir -p /tmp/newRepo/community/${ARCH}
		if [ -e /tmp/newRepo/community/${ARCH}/APKINDEX.tar.gz ]; then rm /tmp/newRepo/community/${ARCH}/APKINDEX.tar.gz; fi
		wget -qP /tmp/newRepo/community/${ARCH} https://dl-cdn.alpinelinux.org/alpine/latest-stable/community/${ARCH}/APKINDEX.tar.gz | tee -a /tmp/upgradeLog
  		if [ ! -e /tmp/newRepo/community/${ARCH}/APKINDEX.tar.gz ]; then
  			echo "Unable to download community repository index for package check.  If you would like to skip this check, use --SKIP_CHECK to skip this function." | tee -a /tmp/upgradeLog
    			exit 1;
      		fi
		echo /tmp/newRepo/community/ >> /tmp/repo
	fi
	if [ -e /tmp/repoMissing ]; then rm /tmp/repoMissing; fi
	echo " #################### PACKAGE IMPACT CHECK ####################" | tee -a /tmp/upgradeLog
	printf " # %28s" "Package" | tee -a /tmp/upgradeLog
 	echo -n "   " | tee -a /tmp/upgradeLog
	printf "%-27s #\n" "Available" | tee -a /tmp/upgradeLog
	echo " #------------------------------------------------------------#" | tee -a /tmp/upgradeLog
	for i in $(apk info); do 
		printf " # %28s" "$i" | tee -a /tmp/upgradeLog
		echo -n " : " | tee -a /tmp/upgradeLog
		if [ $(apk search --allow-untrusted --exact --repositories-file /tmp/repo $i | wc -l) -ge 1 ]; then # Ignore certificate issues since this may be run on a system without up to date CA-Certs, those will be updated later in the installation
			printf "%-27s #\n" "Yes" | tee -a /tmp/upgradeLog
		else
			printf "%-27s #\n" "No" | tee -a /tmp/upgradeLog
			printf " # %28s" "$i" >> /tmp/repoMissing
			echo -n " : " >> /tmp/repoMissing
			printf "%-27s #\n" "No" >> /tmp/repoMissing
		fi
	done
	echo " ##############################################################" | tee -a /tmp/upgradeLog
	echo "" | tee -a /tmp/upgradeLog
	rm -r /tmp/newRepo
	rm /tmp/repo
	if [ -e /tmp/repoMissing ]; then
		echo " ########### WARNING: BROKEN PACKAGES AFTER UPGRADE ###########" | tee -a /tmp/upgradeLog
		echo " #                          Summary                           #" | tee -a /tmp/upgradeLog
		printf " # %28s" "Package" | tee -a /tmp/upgradeLog
  		echo -n "   " | tee -a /tmp/upgradeLog
		printf "%-27s #\n" "Available" | tee -a /tmp/upgradeLog
		echo " #------------------------------------------------------------#" | tee -a /tmp/upgradeLog
		cat /tmp/repoMissing | tee -a /tmp/upgradeLog
		rm /tmp/repoMissing
		echo " ##############################################################" | tee -a /tmp/upgradeLog
		echo "" | tee -a /tmp/upgradeLog
		if [ -z $SKIP_CONFIRM ]; then
			while true; do
   				echo -n "Do you still want to upgrade to the latest Alpine Linux version(y/n)? [n] " | tee -a /tmp/upgradeLog
				read confirm <&1 # Read from stdout instead of stdin since it would just read next line of script when run through pipe
    				echo $confirm >> /tmp/upgradeLog
				if [[ "$confirm" == "y" ]] || [[ "$confirm" == "Y" ]]; then
					echo "User selected to proceed." | tee -a /tmp/upgradeLog
     					break
	  			elif [[ "$confirm" == "n" ]] || [[ "$confirm" == "N" ]] || [[ -z $confirm ]]; then
     					echo "User selected No." | tee -a /tmp/upgradeLog
	  				exit
	  			else
					echo "Please answer yes (y) or no (n)." | tee -a /tmp/upgradeLog
				fi
			done
		else
			echo "### SKIP_CONFIRM SET" | tee -a /tmp/upgradeLog
		fi
	fi
else
	echo "### SKIP_CHECK SET" | tee -a /tmp/upgradeLog
fi

#### Start Update

# Comment out edge repositories so we are on latest stable build
sed -e '/\/edge\// s/^#*/#/' -i /etc/apk/repositories 

# Upgrade all current packages
apk update &> | tee -a /tmp/upgradeLog
apk version -l '<' | tee -a /tmp/upgradeLog
apk upgrade &> | tee -a /tmp/upgradeLog
# apk cache -v clean | tee -a /tmp/upgradeLog
apk cache -v download &> | tee -a /tmp/upgradeLog
apk cache -v sync &> | tee -a /tmp/upgradeLog

# Install run-once finishing script
echo '#!/sbin/openrc-run
name=os-upgrade
command="os-upgrade.sh"
command_args=""
command_user="root"
pidfile="/run/os-upgrade/os-upgrade.pid"
command_background="no"

depend() {
        need net
}

start_pre() {
        checkpath --directory --owner $command_user:$command_user --mode 0775 \
                /run/os-upgrade /var/log/os-upgrade
}
' > /etc/init.d/os-upgrade
chmod +x /etc/init.d/os-upgrade
echo "#!/bin/ash
# Alpine Linux OS Version Updater - Finishing Script
# By: XtendedGreg - https://youtube.com/@XtendedGreg
# Based on https://wiki.alpinelinux.org/wiki/Upgrading_Alpine

echo '' | tee -a /tmp/upgradeLog
echo '########### Alpine Linux OS Upgrade - Finishing Pass #############' | tee -a /tmp/upgradeLog
echo 'Upgrade Script by : XtendedGreg [https://youtube.com/@XtendedGreg] January 4, 2024' | tee -a /tmp/upgradeLog
echo 'Github : https://github.com/XtendedGreg/alpine-os-updater' | tee -a /tmp/upgradeLog
echo 'Based on https://wiki.alpinelinux.org/wiki/Upgrading_Alpine' | tee -a /tmp/upgradeLog
echo '' | tee -a /tmp/upgradeLog

echo 'Moved old repositories list to /etc/apk/repositories.bak' | tee -a /tmp/upgradeLog
mv -v /etc/apk/repositories /etc/apk/repositories.bak &> | tee -a /tmp/upgradeLog

# Verify that APK is configured correctly
# Use first mirror and enable community repository if already enabled
setup-apkrepos -1 $APKREPOS_FLAG &> | tee -a /tmp/upgradeLog
setup-apkcache $APKCACHE &> | tee -a /tmp/upgradeLog

# Upgrade existing packages to the latest version
apk upgrade &> | tee -a /tmp/upgradeLog

# Download Packages to Cache, Sync and Clean
apk cache -v download &> | tee -a /tmp/upgradeLog
apk cache sync &> | tee -a /tmp/upgradeLog
apk cache clean &> | tee -a /tmp/upgradeLog

# Correct packages that did not exist on upgrade
apk fix &> | tee -a /tmp/upgradeLog

rc-update del /etc/init.d/os-upgrade | tee -a /tmp/upgradeLog
lbu exclude /etc/init.d/os-upgrade /bin/os-upgrade.sh &> | tee -a /tmp/upgradeLog
rm /etc/init.d/os-upgrade /bin/os-upgrade.sh

lbu commit &> | tee -a /tmp/upgradeLog

. /etc/lbu/lbu.conf
echo \"########### OS Upgrade Complete - New Version : \$(cat /media/\${LBU_MEDIA}/.alpine-release | awk '{print \$1}') #############\" | tee -a /tmp/upgradeLog
echo 'View upgrade log: /media/$LBU_MEDIA/upgradeLog' | tee -a /tmp/upgradeLog
echo '' | tee -a /tmp/upgradeLog

mount -o remount,rw /media/$LBU_MEDIA
cat /tmp/upgradeLog >> /media/$LBU_MEDIA/upgradeLog
rm /tmp/upgradeLog
mount -o remount,ro /media/$LBU_MEDIA
" > /bin/os-upgrade.sh
chmod +x /bin/os-upgrade.sh
lbu add /etc/init.d/os-upgrade /bin/os-upgrade.sh &> | tee -a /tmp/upgradeLog

echo "Adding post-upgrade run-once script to RC" | tee -a /tmp/upgradeLog
rc-update add os-upgrade default &> | tee -a /tmp/upgradeLog

# Save final config before upgrade starts
lbu commit &> | tee -a /tmp/upgradeLog

cd /media/$LBU_MEDIA
mount -o remount,rw /media/$LBU_MEDIA &> | tee -a /tmp/upgradeLog
cat /tmp/upgradeLog >> upgradeLog
rm /tmp/upgradeLog
wget https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/${ARCH}/alpine-rpi-${LATEST_RELEASE}-${ARCH}.tar.gz &> | tee -a upgradeLog
wget https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/${ARCH}/alpine-rpi-${LATEST_RELEASE}-${ARCH}.tar.gz.sha256 &> | tee -a upgradeLog
if [ $(sha256sum -c alpine-rpi-${LATEST_RELEASE}-${ARCH}.tar.gz.sha256 | grep "alpine-rpi-${LATEST_RELEASE}-${ARCH}.tar.gz: OK" | wc -l) -eq 1 ]; then
	echo "Alpine Linux Release checksum confirmed. Proceeding with upgrade..." | tee -a upgradeLog
 	# Remove old files which will be replaced when new version is extracted
 	rm -r /media/$LBU_MEDIA/apks &> | tee -a /tmp/upgradeLog
  	rm -r /media/$LBU_MEDIA/boot &> | tee -a /tmp/upgradeLog
   	rm -r /media/$LBU_MEDIA/overlays &> | tee -a /tmp/upgradeLog
    	rm /media/$LBU_MEDIA/*.dtb &> | tee -a /tmp/upgradeLog
     	rm /media/$LBU_MEDIA/*.elf &> | tee -a /tmp/upgradeLog
      	rm /media/$LBU_MEDIA/*.dat &> | tee -a /tmp/upgradeLog
       	rm /media/$LBU_MEDIA/bootcode.bin &> | tee -a /tmp/upgradeLog
	rm /media/$LBU_MEDIA/cmdline.txt &> | tee -a /tmp/upgradeLog
 	rm /media/$LBU_MEDIA/config.txt &> | tee -a /tmp/upgradeLog
	#rm /media/$LBU_MEDIA/apks/$ARCH/* # Clear old apk packages from previous version
	#rm /media/$LBU_MEDIA/cache/*
	#apk update | tee -a upgradeLog
	#apk update | tee -a upgradeLog # Needs to be run twice?
	#apk cache -v download | tee -a upgradeLog
	tar xzf alpine-rpi-${LATEST_RELEASE}-${ARCH}.tar.gz &> | tee -a upgradeLog
	rm alpine-rpi-${LATEST_RELEASE}-${ARCH}.tar.gz alpine-rpi-${LATEST_RELEASE}-${ARCH}.tar.gz.sha256 &> | tee -a upgradeLog
	echo "Upgrade Complete.  Syncing drive and rebooting..." | tee -a upgradeLog
	echo "" | tee -a upgradeLog
	sync &> | tee -a upgradeLog
	reboot
else
	echo "DOWNLOADED FILE CHECKSUM FAILURE. ABORTING AND CLEANING UP." | tee -a upgradeLog
	rm alpine-rpi-$LATEST_RELEASE-$ARCH.tar.gz alpine-rpi-$LATEST_RELEASE-$ARCH.tar.gz.sha256 &> | tee -a upgradeLog
	
	rc-update del /etc/init.d/os-upgrade &> | tee -a upgradeLog
	lbu exclude /etc/init.d/os-upgrade /bin/os-upgrade.sh &> | tee -a upgradeLog
	rm /etc/init.d/os-upgrade /bin/os-upgrade.sh &> | tee -a upgradeLog

	lbu commit &>| tee -a upgradeLog
	echo "CLEANUP COMPLETE. EXITING WITH ERROR CODE 1." | tee -a upgradeLog
	echo "View upgrade log: /media/$LBU_MEDIA/upgradeLog" | tee -a upgradeLog
	echo "" | tee -a upgradeLog
	mount -o remount,ro /media/$LBU_MEDIA
	exit 1
fi

exit 0
