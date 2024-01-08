# alpine-os-updater
A script to upgrade the Alpine Linux OS on Raspberry Pi
By XtendedGreg https://youtube.com/@XtendedGreg

## Purpose
 - This script will update an existing installation of Alpine Linux from a previous version to the latest release.  This will perform the upgrade in place and will preserve the community repository inclusion from the previous version for apk.  A reboot is required as part of the upgrade, and a script will run to complete the transition of the apk repository settings, and correcting installations of packages that have to updated automatically on first boot.
 - Since package availability may change from version to version, a check of all existing installed packages will be performed to check if they are available in the repository for the new version.  In the event any packages cannot be migrated to the new version, a prompt will be displayed to confirm that you want to proceed before any changes are made to the system.  If it is accepted, or if there are no issues found, the script will continue with the installation.
 - As part of this installer, all packages will be updated to the latest version available on the current OS version to try to ensure that your system can boot with networking and SSH following the upgrade. By default, this installer will use the latest stable release.

## Expected Performance
 - This script is not designed to fix existing issues with your installation and is only tested to update the OS and supported packages.
 - It is known that it is possible that custom applications may break and need to be updated to address changes in package dependancies with the latest version or the like, so a mechanism has been created to provide information about packages that are currently installed that may no longer exist so that you can make that determination for your use case.
 - Os versions 3.18.0 and higher, have been tested and will complete the upgrade with no significant impact observed.
 - Versions going back to 3.11.2 were tested, but because of package differences was only able to insure that networking and SSH were available after reboot consistently, and while the base OS upgrade was consistently successful, there were issues with packages, like missing packages that were no longer installed, that had to be resolved manually.
 - While testing was performed on all versions of Pi currently available, Alpine Linux was only tested fully to the last major version (3.18.0-3.18.5 going to the current 3.19.0) and then spot checks on versions earlier than that upgrading to 3.19.0. 

## How To Use
 - From ssh or on the console, enter the following command which will download the script and run it
```
wget --no-cache -qO- https://raw.githubusercontent.com/XtendedGreg/alpine-os-updater/main/upgrade.sh | ash
```
 - The install script will reboot automatically and will run some cleanup actions after reboot to make sure apk repositories are pointing to the latest version and that packages are updated and installed to match
 - Once the installation is complete, a log file on the root of the boot media will be present
 - The previous APK repositories list will be moved to ```/etc/apk/repositories.bak``` so that you can manually move any custom repositories

## Troubleshooting
 - If you to receive errors indicating "UNTRUSTED" or an "ssl_client" error when launching the script: This is because the CA Certificates are expired and may be invalid or the date is not set on your Pi.  You may need to manually update ```ca-certificates``` package manually so that the install script can run correctly and/or set the system date manually if it is not syncing through NTP.
 - The startup finishing script experiences errors during first boot following upgrade: While most errors have been noted relating to an incorrect date set on the Pi, once the issues that caused the script not to run successfully are addressed, the startup script can be reattempted by using the same wget command from the 'How To Use' section above.  When the current latest version is detected, you will be prompted if you would like to rerun just the startup script.
