#!/bin/bash
mount -o remount,size=3G /run/archiso/cowspace;
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

yes | pacman -Sy pacman-contrib
#cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
curl -s "https://www.archlinux.org/mirrorlist/?country=$country&protocol=http&protocol=https&ip_version=4&use_mirror_status=on" |
   sed -e 's/^#Server/Server/' -e '/^#/d' |
   rankmirrors -n 5 - > /etc/pacman.d/mirrorlist

echo -e "\ny" | pacman -Sy --force base-devel perl-module-build perl-net-ssleay avahi python2 dbus-glib python2-dbus git \
  squashfs-tools

mkdir -p "$ar_inst"/{archraid/x86_64,boot/x86_64}

cd  "$ar_inst"/archraid/x86_64/

mkdir squashfs-root

pacstrap squashfs-root base archiso zsh

#Pacotes para Webvirtmgr
#yes | pacman -S dmidecode dnsmasq ebtables libvirt-python python2 python2-django python2-gunicorn \
#     python2-lockfile python2-pip bridge-utils python-distribute python-numpy libvirt-python2 supervisor

#Pacote para build websockfy
yes | pacman -S python-distribute

#Pacote para build webvirtmgr
yes | pacman -S python2-pip


#Compila dependências AUR
declare -a aurlist=("perl-authen-pam" "perl-encode-detect" "websockify" "python2-django-auth-ldap")  &&
for package in ${aurlist[@]}; do
    cd /tmp ;
    git clone "https://aur.archlinux.org/$package.git" ;
    cd "$package" || exit;
    chmod -R 777 /usr/lib/python*
    chgrp nobody . &&
    chmod g+ws . &&
    setfacl -m u::rwx,g::rwx . &&
    setfacl -d --set u::rwx,g::rwx,o::- . &&
    sudo -u nobody makepkg ;
    for instPkg in ./*.pkg.tar.xz; do
        yes | pacman -U "$instPkg";
    done;
    chmod -R 755 /usr/lib/python*
done;

#compilar pacotes AUR
declare -a aurlist=("perl-authen-pam" "perl-encode-detect" "webmin" \
 "mergerfs" "snapraid" "netatalk" "bcache-tools" \
 "websockify" "python2-django-auth-ldap" "webvirtmgr-git" ) &&
for package in ${aurlist[@]}; do
    cd /tmp ;
    git clone "https://aur.archlinux.org/$package.git" ;
    cd "$package" || exit;
    chmod -R 777 /usr/lib/python*
    chgrp nobody . &&
    chmod g+ws . &&
    setfacl -m u::rwx,g::rwx . &&
    setfacl -d --set u::rwx,g::rwx,o::- . &&
    sudo -u nobody makepkg -d;
    for instPkg in ./*.pkg.tar.xz; do
        cp "$instPkg" "$ar_inst"/archraid/x86_64/squashfs-root/opt/;
    done;
    chmod -R 755 /usr/lib/python*
done;

cd  "$ar_inst"/archraid/x86_64/

#Reliza instalação dentro do CHRoot
#curl -s http://server/path/script.sh | bash -s arg1 arg2
#!/bin/bash

arch-chroot squashfs-root << EOF
  curl -s -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/cjuniorfox/archraid/master/setup_arch-chroot.sh | bash -s "$hostname"
  exit
EOF

cp squashfs-root/boot/vmlinuz-linux "$ar_inst"/boot/x86_64/vmlinuz-linux
cp squashfs-root/boot/initramfs-linux.img "$ar_inst"/boot/x86_64/initramfs-linux.img
cp squashfs-root/boot/initramfs-linux-fallback.img "$ar_inst"/boot/x86_64/initramfs-linux-fallback.img
cp squashfs-root/boot/memtest86+/memtest.bin "$ar_inst"/boot/memtest
cp squashfs-root/pkglist.txt "$ar_inst"/archraid/pkglist.x86_64.txt

ln -sf /run/archiso/bootmnt/boot/x86_64/vmlinuz-linux "$ar_inst"/boot/vmlinuz-linux
ln -sf /run/archiso/bootmnt/boot/x86_64/initramfs-linux.img "$ar_inst"/boot/initramfs-linux.img
ln -sf /run/archiso/bootmnt/boot/x86_64/initramfs-linux-fallback.img "$ar_inst"/boot/initramfs-linux-fallback.img


mksquashfs \
  boot \
  teste/{bin,dev,etc,home,lib,lib64,mnt,opt,proc,root,run,sbin,srv,sys,tmp,usr,var} \
  filesystem.sfs

#mksquashfs squashfs-root airootfs.sfs -e \
#  boot/vmlinuz-linux \
#  boot/initramfs-linux.img \
#  boot/initramfs-linux-fallback.img \
#  boot/memtest86+ \
#  pkglist.txt

sha512sum airootfs.sfs > airootfs.sha512

##Realiza instalação adicional de ambiente gráfico
#arch-chroot squashfs-root << EOF
#  curl -s -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/cjuniorfox/archraid/master/setup_arch-chroot-gui.sh | bash -
#  exit
#EOF
#
#cp squashfs-root/pkglist.txt "$ar_inst"/archraid-gui/pkglist.x86_64.txt
#
##cria novamente imagem compactada do sistema
#mksquashfs squashfs-root "$ar_inst"/archraid-gui/x86_64/airootfs.sfs -e \
#  boot/vmlinuz-linux \
#  boot/initramfs-linux.img \
#  boot/initramfs-linux-fallback.img \
#  boot/memtest86+ \
#  pkglist.txt
#
#sha512sum "$ar_inst"/archraid-gui/x86_64/airootfs.sfs > "$ar_inst"/archraid-gui/x86_64/airootfs.sha512
rm -r squashfs-root
