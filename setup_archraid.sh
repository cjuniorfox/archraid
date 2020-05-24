#!/bin/sh
sudo -s
if [ -z $ar_inst ]; then
	ar_inst=$(whiptail --inputbox --title "ArchRAID" "Input archraid chroot installation directory" 8 50 3>&1 1>&2 2>&3)
	if [ -z "$ar_inst" ]; then 
        	exit;
    fi;
fi;
if [ -z $country ]; then
	country=$(whiptail --inputbox --title "ArchRAID" "Input your country for Pacman's repository" 8 50 3>&1 1>&2 2>&3)
	if [ -z "$country" ]; then 
  			exit;
  	fi;
fi;
if [ -z $hostname ]; then
  hostname=$(whiptail --inputbox --title "ArchRAID" "Input your desired hostname" 8 50 3>&1 1>&2 2>&3)
  if [ -z "$hostname" ]; then 
        exit;
    fi;
fi;
pacman -Sy --noconfirm base-devel git make squashfs-tools
mkdir -p "$ar_inst"/archraid/{boot/x86_64,x86_64/{boot,squashfs-root}}
cd  "$ar_inst"/archraid/x86_64/ &&
pacstrap squashfs-root base archiso
pacman -S --noconfirm \
  expac \
  python-requests \
  python-regex \
  python-dateutil \
  pyalpm \
  python-feedparser

#key from aurman
#sudo -u ___aur gpg --recv-keys 465022E743D71E39
pacman -S go --noconfirm
declare -a aurlist=("yay") &&
for package in ${aurlist[@]}; do
    cd /tmp ;
    git clone "https://aur.archlinux.org/$package.git" ;
    cd "$package" || exit;
    chgrp ___aur . &&
    chmod g+ws . &&
    setfacl -m u::rwx,g::rwx . &&
    setfacl -d --set u::rwx,g::rwx,o::- . &&
    sudo -u ___aur makepkg -d;
    for instPkg in ./*.pkg.tar.xz; do
        cp "$instPkg" "$ar_inst"/archraid/x86_64/squashfs-root/opt/;
    done;
done;

userdel ___aur;

cd  "$ar_inst"/archraid/x86_64/

arch-chroot squashfs-root << EOF
  curl -sL "https://raw.githubusercontent.com/cjuniorfox/archraid/master/setup_arch-chroot.sh" | bash -s "$hostname"
  exit
EOF

cp squashfs-root/boot/vmlinuz-linux                 "$ar_inst"/archraid/boot/x86_64/vmlinuz-linux
cp squashfs-root/boot/initramfs-linux.img           "$ar_inst"/archraid/boot/x86_64/initramfs-linux.img
cp squashfs-root/boot/initramfs-linux-fallback.img  "$ar_inst"/archraid/boot/x86_64/initramfs-linux-fallback.img
cp squashfs-root/boot/memtest86+/memtest.bin        "$ar_inst"/archraid/boot/memtest
cp squashfs-root/pkglist.txt                        "$ar_inst"/archraid/pkglist.x86_64.txt

ln -sf /run/archiso/bootmnt/boot/x86_64/vmlinuz-linux                 boot/vmlinuz-linux
ln -sf /run/archiso/bootmnt/boot/x86_64/initramfs-linux.img           boot/initramfs-linux.img
ln -sf /run/archiso/bootmnt/boot/x86_64/initramfs-linux-fallback.img  boot/initramfs-linux-fallback.img
