# alpine-os-updater
A script to upgrade the Alpine Linux OS on Raspberry Pi

## Purpose
This script will update an existing installation of Alpine Linux from a previous version to the latest release.  This will perform the upgrade in place and will preserve the community repository inclusion from the previous version for apk.  A reboot is required as part of the upgrade, and a script will run to complete the transition of the apk repository settings, and correcting installations of packages that have to updated automatically on first boot.  Since package availability may change from version to version, a check of all existing installed packages will be performed to check if they are available in the repository for the new version.  In the event any packages cannot be migrated to the new version, a prompt will be displayed to confirm that you want to proceed before any changes are made to the system.  If it is accepted, or if there are no issues found, the script will continue with the installation.  As part of this installer, all packages will be updated to the latest version available on the current OS version to try to ensure that your system can boot with networking following the upgrade. By default, this installer with use the latest stable release.

## How To Use
 - From ssh or on the console, enter the following command which will download the script and run it
```
wget --no-cache -qO- https://raw.githubusercontent.com/XtendedGreg/alpine-os-updater/main/upgrade.sh | ash
```
 - The install script will reboot automatically and will run some cleanup actions after reboot to make sure apk repositories are pointing to the latest version and that packages are updated and installed to match
 - Once the installation is complete, a log file on the root of the boot media will be present
 - The previous APK repositories list will be moved to ```/etc/apk/repositories.bak``` so that you can manually move any custom repositories

## Only Run This On A Raspberry Pi
This only works on Raspberry Pi Installations due to the differences in the way the image is loaded vs other architectures that will break the bootloader.

## Troubleshooting
 - If after running this script you end up on a more recent version than the current stable version (edge), it is because you have the edge repositories enabled in ```/etc/apk/repositories``` prior to the upgrade.  Remove the references to the edge repositories and rerun the installer which should bring you back to the latest stable version.
 - If during during the initial package update part of the installation, you start to receive errors indicating "UNTRUSTED" or an "ssl_client" error when launching the script, this is because the CA Certificates are expired and may be invalid.  You may need to manually run ```apk update``` manually until those errors clear before reattempting the script, or updating ```ca-certificates``` package manually so that the install script can run correctly.
