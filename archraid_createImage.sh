#!/bin/bash
mount -o remount,size=3G /run/archiso/cowspace;
if [ -z $ar_inst ]; then
		ar_inst=$(whiptail --inputbox --title "ArchRAID" "Input archraid chroot installation directory" 8 50 3>&1 1>&2 2>&3)
		if [ -z "$ar_inst" ]; then 
  				exit;
  		fi;
fi;

if [ -z $country ]; then
		country=$(whiptail --inputbox --title "ArchRAID" "Input your country for pacman's repository" 8 50 3>&1 1>&2 2>&3)
		if [ -z "$country" ]; then 
  				exit;
  		fi;
fi;

yes | pacman -Sy pacman-contrib
#cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
curl -s "https://www.archlinux.org/mirrorlist/?country=$country&protocol=http&protocol=https&ip_version=4&use_mirror_status=on" |
   sed -e 's/^#Server/Server/' -e '/^#/d' |
   rankmirrors -n 5 - > /etc/pacman.d/mirrorlist

echo -e "\ny" | pacman -Sy --force base-devel perl-module-build perl-net-ssleay avahi python2 dbus-glib python2-dbus git \
  squashfs-tools

mkdir -p "$ar_inst"/{archraid,archraid-gui}/{x86_64,boot/x86_64}

cd  "$ar_inst"/archraid/x86_64/

mkdir squashfs-root

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
        cp "$instPkg" "$ar_inst"/archraid/x86_64/squashfs-root/opt/;
    done;
done;

cd  "$ar_inst"/archraid/x86_64/

#Reliza instalação dentro do CHRoot
#curl -s http://server/path/script.sh | bash -s arg1 arg2
#!/bin/bash

arch-chroot squashfs-root << EOF
  curl -s -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/cjuniorfox/archraid/master/setup_arch-chroot.sh | bash -
  exit
EOF

cp squashfs-root/boot/vmlinuz-linux "$ar_inst"/boot/x86_64/vmlinuz-linux
cp squashfs-root/boot/initramfs-linux.img "$ar_inst"/boot/x86_64/initramfs-linux.img
cp squashfs-root/boot/initramfs-linux-fallback.img "$ar_inst"/boot/x86_64/initramfs-linux-fallback.img
cp squashfs-root/boot/memtest86+/memtest.bin "$ar_inst"/boot/memtest
cp squashfs-root/pkglist.txt "$ar_inst"/archraid/pkglist.x86_64.txt

mksquashfs squashfs-root airootfs.sfs -e \
  boot/vmlinuz-linux \
  boot/initramfs-linux.img \
  boot/initramfs-linux-fallback.img \
  boot/memtest86+ \
  pkglist.txt

sha512sum airootfs.sfs > airootfs.sha512

#Realiza instalação adicional de ambiente gráfico
arch-chroot squashfs-root << EOF
  curl -s -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/cjuniorfox/archraid/master/setup_arch-chroot-gui.sh | bash -
  exit
EOF

cp squashfs-root/pkglist.txt "$ar_inst"/archraid-gui/pkglist.x86_64.txt

#cria novamente imagem compactada do sistema
mksquashfs squashfs-root "$ar_inst"/archraid-gui/x86_64/airootfs.sfs -e \
  boot/vmlinuz-linux \
  boot/initramfs-linux.img \
  boot/initramfs-linux-fallback.img \
  boot/memtest86+ \
  pkglist.txt

sha512sum "$ar_inst"/archraid-gui/x86_64/airootfs.sfs > "$ar_inst"/archraid-gui/x86_64/airootfs.sha512
rm -r squashfs-root
