#!/bin/ash
# Alpine Linux OS Version Updater
# By: XtendedGreg - https://youtube.com/@XtendedGreg
# Github: https://github.com/XtendedGreg/alpine-os-updater
# Based on https://wiki.alpinelinux.org/wiki/Upgrading_Alpine

echo "########### OS Upgrade Start - Initial Pass #############" | tee /tmp/upgradeLog
echo "Upgrade Script by : XtendedGreg [https://youtube.com/@XtendedGreg] January 4, 2024" | tee -a /tmp/upgradeLog
echo "Github : https://github.com/XtendedGreg/alpine-os-updater" | tee -a /tmp/upgradeLog
echo "Based on https://wiki.alpinelinux.org/wiki/Upgrading_Alpine" | tee -a /tmp/upgradeLog
echo "Start Date : $(date)" | tee -a /tmp/upgradeLog

. /etc/os-release
. /etc/lbu/lbu.conf

ARCH=$(cat /etc/apk/arch)
ALPINE_RELEASE=$(cat /media/${LBU_MEDIA}/.alpine-release | awk '{print $1}')
LATEST_RELEASE=$(wget -qO- https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/${ARCH}/latest-releases.yaml | grep version | head -n1 | awk '{print $2}')
COMMUNITY_ENABLED=$(cat /etc/apk/repositories | grep community | grep -e "^#http" | wc -l)

if [ $COMMUNITY_ENABLED -eq 1 ]; then
	APKREPOS_FLAG=""
else
	APKREPOS_FLAG="-c"
fi

# Exit if the latest version of Alpine Linux is already installed
if [[ "$(echo $ALPINE_RELEASE | tr -d ' ')" == "$(echo $LATEST_RELEASE | tr -d ' ')" ]]; then
	echo "Already the latest version of Alpine Linux. Move along, nothing to see here." | tee -a /tmp/upgradeLog
	exit 0
fi

# Update all current packages
apk update | tee -a /tmp/upgradeLog
apk version -l '<' | tee -a /tmp/upgradeLog
apk upgrade | tee -a /tmp/upgradeLog

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

echo '' | tee /tmp/upgradeLog
echo '########### OS Upgrade - Finishing Pass #############' | tee -a /tmp/upgradeLog
echo 'Upgrade Script by : XtendedGreg [https://youtube.com/@XtendedGreg] January 4, 2024' | tee -a /tmp/upgradeLog
echo 'Github : https://github.com/XtendedGreg/alpine-os-updater' | tee -a /tmp/upgradeLog
echo 'Based on https://wiki.alpinelinux.org/wiki/Upgrading_Alpine' | tee -a /tmp/upgradeLog
echo '' | tee /tmp/upgradeLog

echo 'Moved old repositories list to /etc/apk/repositories.bak' | tee -a /tmp/upgradeLog
mv /etc/apk/repositories /etc/apk/repositories.bak

setup-apkrepos -1 $APKREPOS_FLAG | tee -a /tmp/upgradeLog #Use first mirror and enable community repository if already enabled
apk cache sync | tee -a /tmp/upgradeLog
apk cache clean | tee -a /tmp/upgradeLog

# Correct packages that did not exist on upgrade
apk add | tee -a /tmp/upgradeLog

rc-update del /etc/init.d/os-upgrade | tee /tmp/upgradeLog
lbu exclude /etc/init.d/os-upgrade /bin/os-upgrade.sh | tee -a /tmp/upgradeLog
rm /etc/init.d/os-upgrade /bin/os-upgrade.sh

lbu commit | tee -a /tmp/upgradeLog

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
lbu add /etc/init.d/os-upgrade /bin/os-upgrade.sh | tee -a /tmp/upgradeLog

echo "Adding post-upgrade run-once script to RC" | tee -a /tmp/upgradeLog
rc-update add os-upgrade default | tee -a /tmp/upgradeLog

# Save final config before upgrade starts
lbu commit

echo "" | tee -a /tmp/upgradeLog
echo "########### OS UPGRADE DETAILS ########### " | tee -a /tmp/upgradeLog
echo "" | tee -a /tmp/upgradeLog
echo "      Current Alpine Version : $VERSION_ID" | tee -a /tmp/upgradeLog
echo "       Latest Alpine Version : $LATEST_RELEASE" | tee -a /tmp/upgradeLog
echo "                   LBU Media : $LBU_MEDIA" | tee -a /tmp/upgradeLog
echo "                Architecture : $ARCH" | tee -a /tmp/upgradeLog

if [ $COMMUNITY_ENABLED -eq 1 ]; then
	echo "Community Repository Enabled : No" | tee -a /tmp/upgradeLog
else
	echo "Community Repository Enabled : Yes" | tee -a /tmp/upgradeLog
fi
echo "" | tee -a /tmp/upgradeLog
echo "########################################## " | tee -a /tmp/upgradeLog
echo "" | tee -a /tmp/upgradeLog

cd /media/$LBU_MEDIA
mount -o remount,rw /media/$LBU_MEDIA
cat /tmp/upgradeLog >> upgradeLog
rm /tmp/upgradeLog
wget https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/${ARCH}/alpine-rpi-${LATEST_RELEASE}-${ARCH}.tar.gz | tee -a upgradeLog
wget https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/${ARCH}/alpine-rpi-${LATEST_RELEASE}-${ARCH}.tar.gz.sha256 | tee -a upgradeLog
if [ $(sha256sum -c alpine-rpi-${LATEST_RELEASE}-${ARCH}.tar.gz.sha256 | grep "alpine-rpi-${LATEST_RELEASE}-${ARCH}.tar.gz: OK" | wc -l) -eq 1 ]; then
	echo "Alpine Linux Release checksum confirmed. Proceeding with upgrade..." | tee -a upgradeLog
	rm /media/$LBU_MEDIA/apks/$ARCH/*
	rm /media/$LBU_MEDIA/cache/*
	apk update | tee -a upgradeLog
	apk update | tee -a upgradeLog # Needs to be run twice?
	apk cache -v download | tee -a upgradeLog
	tar xzf alpine-rpi-${LATEST_RELEASE}-${ARCH}.tar.gz | tee -a upgradeLog
	rm alpine-rpi-${LATEST_RELEASE}-${ARCH}.tar.gz alpine-rpi-${LATEST_RELEASE}-${ARCH}.tar.gz.sha256
	echo "Upgrade Complete.  Syncing drive and rebooting..." | tee -a upgradeLog
	echo "" | tee -a upgradeLog
	sync
	reboot
else
	echo "DOWNLOADED FILE CHECKSUM FAILURE. ABORTING AND CLEANING UP." | tee -a upgradeLog
	rm alpine-rpi-$LATEST_RELEASE-$ARCH.tar.gz alpine-rpi-$LATEST_RELEASE-$ARCH.tar.gz.sha256
	
	rc-update del /etc/init.d/os-upgrade | tee -a upgradeLog
	lbu exclude /etc/init.d/os-upgrade /bin/os-upgrade.sh | tee -a upgradeLog
	rm /etc/init.d/os-upgrade /bin/os-upgrade.sh

	lbu commit | tee -a upgradeLog
	echo "CLEANUP COMPLETE. EXITING WITH ERROR CODE 1." | tee -a upgradeLog
	echo "View upgrade log: /media/$LBU_MEDIA/upgradeLog" | tee -a upgradeLog
	echo "" | tee -a upgradeLog
	mount -o remount,ro /media/$LBU_MEDIA
	exit 1
fi

exit 0
