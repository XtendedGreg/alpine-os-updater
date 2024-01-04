# alpine-os-updater
A script to upgrade the Alpine Linux OS on Raspberry Pi

## Purpose
This script will update an existing installation of Alpine Linux from a previous version to the latest release.

## How To Use
 - From ssh or on the console, enter the following command which will download the script and run it
```
wget -qO- https://raw.githubusercontent.com/XtendedGreg/alpine-os-updater/main/upgrade.sh | ash
```
 - The install script will reboot automatically and will run some cleanup actions after reboot to make sure apk repositories are pointing to the latest version and that packages are updated and installed to match
 - Once the installation is complete, a log file on the root of the boot media will be present
 - The previous APK repositories list will be moved to ```/etc/apk/repositories.bak``` so that you can manually move any custom repositories

## Only Run This On A Raspberry Pi
This only works on Raspberry Pi Installations due to the differences in the way the image is loaded vs other architectures that will break the bootloader.
