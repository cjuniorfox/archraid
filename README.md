# archraid
Script to create a Linux Raid based Thumb drive installation with KVM-Qemu, SnapRAID, bcache and more.

## Introduction
Archraid is a customizable installation of Arch Linux to be deployed on Thumb drive and manage:
* Raid (Snapraid, LVM or wherever)
* Shares (SMB/Windows and AFP/MacOS)
* KVM Virtual machines

I do not maitain no archives. Everithing is build straight from Pacman's Arch Linux and AUR repository.

## Disclaimer

Because this runs from sudo, install a lot of things and do some risky activities, like format disks and so on, I don't recommend you execute straight from your working machine. 
Is desirable boot up from ArchIso Live (phisically disconnecting every important HD and SSD from your computer) or running from virtual machine session (Virtualbox or something like that). In script it is planned to resize the persistence disk (cowspace) in RAM to 3Gb  


## Prerequisits
* A ArhLinux or other Pacman distribution (Live ArchISO session recommended. See: https://www.archlinux.org/download/)
* At least 4Gb RAM
* Thumbdrive with 2GB (4GB is recommended)

For single GPU Passthrough, see:
https://github.com/joeknock90/Single-GPU-Passthrough/blob/master/README.md

## Post Installation
