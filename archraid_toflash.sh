 #!/bin/bash
 label="AR20190507";

 mkdir -p ~/mnt/{efi,image}

 parted --script $disk \
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
        name 4 persistence

gdisk $disk << EOF
r     # recovery and transformation options
h     # make hybrid MBR
1 2 3 # partition numbers for hybrid MBR
N     # do not place EFI GPT (0xEE) partition first in MBR
EF    # MBR hex code
N     # do not set bootable flag
EF    # MBR hex code
Y     # do not set bootable flag
83    # MBR hex code
N     # set the bootable flag
x     # extra functionality menu
h     # recompute CHS values in protective/hybrid MBR
w     # write table to disk and exit
Y     # confirm changes
EOF

 mkfs.vfat -F32 -n "EFI" ${disk}2 &&
 mkfs.vfat -F32 ${disk}3 -n "$label" &&
 mkfs.ext4 ${disk}4 -L cow

 sgdisk -A 3:set:2 $disk

 mount ${disk}2 ~/mnt/efi &&
 mount ${disk}3 ~/mnt/image


cd ~/customiso/
cp -Rv * ~/mnt/image

#uefi
mkdir mnt && mount -o loop ./EFI/archiso/efiboot.img mnt &&
cp -Rv mnt/* ~/mnt/efi
umount mnt && rm -rf 

#boot legacy
cd ~/mnt/image
mkdir syslinux
mv isolinux/isolinux.cfg syslinux/syslinux.cfg
rm -rf isolinux
dd conv=notrunc bs=440 count=1 if=/usr/lib/syslinux/bios/gptmbr.bin of=$disk
extlinux -i syslinux
syslinux -i ${disk}3 -d syslinux