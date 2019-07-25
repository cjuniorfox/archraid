# ArchRAID
Script to create a Linux Raid based Thumb drive installation with KVM-Qemu, SnapRAID, bcache and more.

## Introduction
Archraid is a customizable installation of Arch Linux to be deployed on Thumb drive and manage:
* Raid (Snapraid, LVM or wherever)
* Shares (SMB/Windows and AFP/MacOS)
* KVM Virtual machines

I do not maitain no archives. Everithing is build straight from Pacman's Arch Linux and AUR repository.

## Disclaimer

Because the script runs straight from sudo, install a lot of things (to build the image) and do some risky actions (like partition and format a thumbdrive) and so on, I do not recommend make an image from your workstation machine. Is highty desirable to boot up from ArchIso Live session (phisically disconnecting every HD and SSD with important data from your computer) or running from virtual machine session, like Virtualbox or something (recommended way). If you runs from ArchISO session, the script resize the persistence disk (cowspace) in RAM to 3Gb.


## Prerequisites
* A ArhLinux or other Pacman distribution (Live ArchISO session recommended. See: https://www.archlinux.org/download/)
* At least 4Gb RAM
* Thumbdrive with 2GB (4GB is recommended)

For single GPU Passthrough, see:
https://github.com/joeknock90/Single-GPU-Passthrough/blob/master/README.md

## Post Installation

### Webvirtmgr

#### Webvirtmgr. After instal, run this post installation commands:

```
PYTHONPATH=/usr/lib/webvirtmgr/lib python2 /usr/lib/webvirtmgr/manage.py syncdb
chown webvirtmgr:webvirtmgr /usr/lib/webvirtmgr/webvirtmgr/local/.secret_key_store /usr/lib/webvirtmgr/webvirtmgr.sqlite3 /usr/lib/webvirtmgr 
# temporary, see https://github.com/retspen/webvirtmgr/issues/391
PYTHONPATH=/usr/lib/webvirtmgr/lib python2 /usr/lib/webvirtmgr/manage.py collectstatic
```
### Enable Hugepages (improve performance)
https://kyau.net/wiki/ArchLinux:KVM#Hugepages

### To Virtualize MacOS
https://passthroughpo.st/new-and-improved-mac-os-tutorial-part-1-the-basics/

### Setup bridge to share network adapter with KVM guests
https://www.cyberciti.biz/faq/how-to-add-network-bridge-with-nmcli-networkmanager-on-linux/
