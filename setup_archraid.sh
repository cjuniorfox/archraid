#!/bin/sh
sudo -s
if [ -z $ar_inst ]; then
	ar_inst=$(whiptail --inputbox --title "ArchRAID" "Input archraid chroot installation directory" 8 50 3>&1 1>&2 2>&3)
	if [ -z "$ar_inst" ]; then 
        	exit;
    fi;
fi;
if [ -z $hostname ]; then
  hostname=$(whiptail --inputbox --title "ArchRAID" "Input your desired hostname" 8 50 3>&1 1>&2 2>&3)
  if [ -z "$hostname" ]; then 
        exit;
    fi;
fi;
pacman -Sy --noconfirm base-devel git make squashfs-tools expac \
  python-requests \
  python-regex \
  python-dateutil \
  pyalpm \
  python-feedparser \
  go

mkdir -p "$ar_inst"/{boot/x86_64,x86_64/{boot,squashfs-root}}
cd  "$ar_inst"/x86_64/ &&
pacstrap squashfs-root base archiso
useradd ___aur -ms /bin/bash &&
declare -a aurlist=("yay")
for package in ${aurlist[@]}; do
    cd /tmp ;
    git clone "https://aur.archlinux.org/$package.git" ;
    cd "$package" || exit;
    chgrp ___aur . &&
    chmod g+ws . &&
    setfacl -m u::rwx,g::rwx . &&
    setfacl -d --set u::rwx,g::rwx,o::- . &&
    sudo -u ___aur makepkg -df;
    for instPkg in ./*.pkg.tar.xz; do
        cp "$instPkg" "$ar_inst"/x86_64/squashfs-root/opt/;
    done;
    rm -rf /tmp/"$package"
done
userdel ___aur
rm -rf /home/___aur;

cd  "$ar_inst"/x86_64/

arch-chroot squashfs-root << EOF
  curl -sL "https://raw.githubusercontent.com/cjuniorfox/archraid/master/setup_arch-chroot.sh" | bash -s "$hostname"
  exit
EOF

cp squashfs-root/boot/vmlinuz-linux                 "$ar_inst"/boot/x86_64/vmlinuz-linux
cp squashfs-root/boot/initramfs-linux.img           "$ar_inst"/boot/x86_64/initramfs-linux.img
cp squashfs-root/boot/initramfs-linux-fallback.img  "$ar_inst"/boot/x86_64/initramfs-linux-fallback.img
cp squashfs-root/boot/memtest86+/memtest.bin        "$ar_inst"/boot/memtest
cp squashfs-root/pkglist.txt                        "$ar_inst"/pkglist.x86_64.txt

#ln -sf /run/archiso/bootmnt/boot/x86_64/vmlinuz-linux                 boot/vmlinuz-linux
#ln -sf /run/archiso/bootmnt/boot/x86_64/initramfs-linux.img           boot/initramfs-linux.img
#ln -sf /run/archiso/bootmnt/boot/x86_64/initramfs-linux-fallback.img  boot/initramfs-linux-fallback.img
