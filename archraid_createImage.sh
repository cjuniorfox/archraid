#!/bin/bash
#mount -o remount,size=3G /run/archiso/cowspace
if [ -z $ar_inst]; then
		ar_inst=$(whiptail --inputbox --title "ArchRAID" "Input archraid chroot installation directory" 8 50 3>&1 1>&2 2>&3)
		if [ -z "$ar_inst" ]; then 
  				break
  		fi
fi

if [ -z $country]; then
		country=$(whiptail --inputbox --title "ArchRAID" "Input your country for pacman's repository" 8 50 3>&1 1>&2 2>&3)
		if [ -z "$country" ]; then 
  				break
  		fi
fi

yes | pacman -Sy pacman-contrib
#cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
curl -s "https://www.archlinux.org/mirrorlist/?country=$country&protocol=http&protocol=https&ip_version=4&use_mirror_status=on" |
   sed -e 's/^#Server/Server/' -e '/^#/d' |
   rankmirrors -n 5 - > /etc/pacman.d/mirrorlist

echo -e "\ny" | pacman -Sy --force base-devel perl-module-build perl-net-ssleay avahi python2 dbus-glib python2-dbus git \
  squashfs-tools

mkdir -p "$ar_inst"/arch/{x86_64/squashfs-root,boot/x86_64}

cd  "$ar_inst"/arch/x86_64/

pacstrap squashfs-root base archiso zsh

#Compila dependências AUR
declare -a aurlist=("perl-authen-pam" "perl-encode-detect")  &&
for package in ${aurlist[@]}; do
    cd /tmp ;
    git clone "https://aur.archlinux.org/$package.git" ;
    cd "$package" || exit;
    chgrp nobody . &&
    chmod g+ws . &&
    setfacl -m u::rwx,g::rwx . &&
    setfacl -d --set u::rwx,g::rwx,o::- . &&
    sudo -u nobody makepkg ;
    for instPkg in ./*.pkg.tar.xz; do
        yes | pacman -U "$instPkg";
    done;
done;

#compilar pacotes AUR
declare -a aurlist=("perl-authen-pam" "perl-encode-detect" "webmin" "mergerfs" "snapraid" "netatalk" "bcache-tools") &&
for package in ${aurlist[@]}; do
    cd /tmp ;
    git clone "https://aur.archlinux.org/$package.git" ;
    cd "$package" || exit;
    chgrp nobody . &&
    chmod g+ws . &&
    setfacl -m u::rwx,g::rwx . &&
    setfacl -d --set u::rwx,g::rwx,o::- . &&
    sudo -u nobody makepkg ;
    for instPkg in ./*.pkg.tar.xz; do
        cp "$instPkg" "$ar_inst"/arch/x86_64/squashfs-root/opt/;
    done;
done;

cd  "$ar_inst"/arch/x86_64/

#Reliza instalação dentro do CHRoot
#curl -s http://server/path/script.sh | bash -s arg1 arg2
curl -s -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/cjuniorfox/archraid/master/setup_arch-chroot.sh | bash -

mv squashfs-root/boot/vmlinuz-linux "$ar_inst"/arch/boot/x86_64/vmlinuz-linux
mv squashfs-root/boot/initramfs-linux.img "$ar_inst"/arch/boot/x86_64/initramfs-linux.img
mv squashfs-root/boot/initramfs-linux-fallback.img "$ar_inst"/arch/boot/x86_64/initramfs-linux-fallback.img
mv squashfs-root/boot/memtest86+/memtest.bin "$ar_inst"/arch/boot/memtest
mv squashfs-root/pkglist.txt "$ar_inst"/arch/pkglist.x86_64.txt

mksquashfs squashfs-root airootfs.sfs
rm -r squashfs-root
sha512sum airootfs.sfs > airootfs.sha512

