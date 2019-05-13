#!/bin/bash

if [ -z $ar_inst ]; then
        ar_inst=$(whiptail --inputbox --title "ArchRAID" "Input archraid chroot installation directory" 8 50 3>&1 1>&2 2>&3);
        if [ -z "$ar_inst" ]; then 
                exit;
        fi;
fi;

if [ -z $label ]; then
        label=$(whiptail --inputbox --title "ArchRAID" "Input installation's label" 8 50 3>&1 1>&2 2>&3);
        if [ -z "$label" ]; then 
                exit;
        fi;
fi;

if [ -z $disk ]; then
        disk=$(whiptail --inputbox --title "ArchRAID" "Input desired block device" 8 50 3>&1 1>&2 2>&3);
        if [ -z "$disk" ]; then 
                exit;
        fi;
fi;

mkdir -p $ar_inst/mnt/{efi,image} ;

parted --script "$disk" \
    mklabel gpt \
    mkpart primary fat32 2048s 4095s \
        name 1 BIOS \
        set 1 bios_grub on \
    mkpart ESP fat32 4096s 413695s \
        name 2 EFI \
        set 2 esp on \
    mkpart primary fat32 413696s 8226562s \
        name 3 LINUX \
        set 3 msftdata on \
    mkpart primary ext4 8226563s 100% \
        name 4 persistence ;

gdisk $disk << EOF
r     # recovery and transformation options
h     # make hybrid MBR
1 2 3 # partition numbers for hybrid MBR
N     # do not place EFI GPT (0xEE) partition first in MBR
EF    # MBR hex code
N     # do not set bootable flag
EF    # MBR hex code
N     # do not set bootable flag
83    # MBR hex code
Y     # set the bootable flag
x     # extra functionality menu
h     # recompute CHS values in protective/hybrid MBR
w     # write table to disk and exit
Y     # confirm changes
EOF

yes | mkfs.vfat -F32 -n "EFI" ${disk}2 &&
yes | mkfs.vfat -F32 ${disk}3 -n "$label" &&
yes | mkfs.ext4 ${disk}4 -L cow ;

mount ${disk}2 $ar_inst/mnt/efi &&
mount ${disk}3 $ar_inst/mnt/image ;

mkdir -p $ar_inst/mnt/image/{boot/{x86_64,grub},archraid/x86_64} ;

#File to load archraid boot
touch $ar_inst/mnt/image/ARCHRAID ;

cp -v $ar_inst/archraid/x86_64/{airootfs.sfs,airootfs.sha512} $ar_inst/mnt/image/archraid/x86_64/ ;
cp -v $ar_inst/archraid/boot/x86_64/{vmlinuz-linux,initramfs-linux.img,initramfs-linux-fallback.img} $ar_inst/mnt/image/boot/x86_64/ ;
cp -v $ar_inst/archraid/boot/memtest $ar_inst/mnt/image/boot/ ;


#grub menu
cat << EOF > $ar_inst/mnt/image/boot/grub/grub.cfg
search --set=root --file /ARCHRAID
insmod all_video
set default="0"
set timeout=5
menuentry "ArchRaid x86_64 USB" {
    linux /boot/x86_64/vmlinuz-linux archisobasedir=arch archisolabel=$label cow_label=cow intel_iommu=on
    initrd /boot/x86_64/initramfs-linux.img
}
menuentry "ArchRaid x86_64 USB (fallback)" {
    linux /boot/x86_64/vmlinuz-linux archisobasedir=arch archisolabel=$label cow_label=cow intel_iommu=on
    initrd /boot/x86_64/initramfs-linux-fallback.img
}
menuentry "Run Memtest86+" {
    linux /boot/memtest
}
EOF

#UEFI boot installation
grub-install \
    --target=x86_64-efi \
    --efi-directory=$ar_inst/mnt/efi \
    --boot-directory=$ar_inst/mnt/image/boot \
    --removable \
    --recheck

#Legacy Bios boot installation
grub-install \
    --target=i386-pc \
    --boot-directory=$ar_inst/mnt/image/boot \
    --recheck \
    $disk