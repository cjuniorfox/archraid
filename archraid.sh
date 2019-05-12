#!/bin/bash
#aumentando espaço live
mount -o remount,size=3G /run/archiso/cowspace

yes | pacman -Sy pacman-contrib
#cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
curl -s "https://www.archlinux.org/mirrorlist/?country=BR&protocol=http&protocol=https&ip_version=4&use_mirror_status=on" |
   sed -e 's/^#Server/Server/' -e '/^#/d' |
   rankmirrors -n 5 - > /etc/pacman.d/mirrorlist

#instalar pacotes pacman necessários para compilação
# [perl-encode-detect] - perl-module-build
# [Webmin]   - perl-net-ssleay 
# [Netatalk] - avahi python2 dbus-glib python2-dbus
echo -e "\ny" | pacman -S --force base-devel perl-module-build perl-net-ssleay avahi python2 dbus-glib python2-dbus git \
  squashfs-tools

#Extrai ArchISO
mkdir /mnt/archiso
mount /dev/cdrom /mnt/archiso
cp -a /mnt/archiso ~/customiso
cd ~/customiso/arch/x86_64
unsquashfs airootfs.sfs
rm  ./airootfs.sfs
cp ../boot/x86_64/vmlinuz squashfs-root/boot/vmlinuz-linux
cp /etc/pacman.d/mirrorlist ./squashfs-root/etc/pacman.d/mirrorlist


#Compila dependências AUR
declare -a aurlist=("perl-authen-pam" "perl-encode-detect")  &&
for package in ${aurlist[@]}; do
    cd /tmp
    git clone "https://aur.archlinux.org/$package.git"
    cd "$package" || exit;
    chgrp nobody . &&
    chmod g+ws . &&
    setfacl -m u::rwx,g::rwx . &&
    setfacl -d --set u::rwx,g::rwx,o::- . &&
    sudo -u nobody makepkg &&
    for instPkg in ./*.pkg.tar.xz; do
        yes | pacman -U "$instPkg";
    done;
done;

#compilar pacotes AUR
declare -a aurlist=("perl-authen-pam" "perl-encode-detect" "webmin" "mergerfs" "snapraid" "netatalk" "bcache-tools") &&
for package in ${aurlist[@]}; do
    cd /tmp
    git clone "https://aur.archlinux.org/$package.git"
    cd "$package" || exit;
    chgrp nobody . &&
    chmod g+ws . &&
    setfacl -m u::rwx,g::rwx . &&
    setfacl -d --set u::rwx,g::rwx,o::- . &&
    sudo -u nobody makepkg &&
    for instPkg in ./*.pkg.tar.xz; do
        cp "$instPkg" ~/customiso/arch/x86_64/squashfs-root/opt/;
    done;
done;

cd ~/customiso/arch/x86_64

#Reliza instalação dentro do CHRoot
#curl -s http://server/path/script.sh | bash -s arg1 arg2
curl -s https://raw.githubusercontent.com/cjuniorfox/archraid/master/setup_arch-chroot.sh | bash

mv squashfs-root/boot/vmlinuz-linux ~/customiso/arch/boot/x86_64/vmlinuz
mv squashfs-root/boot/initramfs-linux.img ~/customiso/arch/boot/x86_64/archiso.img
rm squashfs-root/boot/initramfs-linux-fallback.img
mv squashfs-root/pkglist.txt ~/customiso/arch/pkglist.x86_64.txt

mksquashfs squashfs-root airootfs.sfs
rm -r squashfs-root
sha512sum airootfs.sfs > airootfs.sha512

iso_label="AR20190507"
mkdir mnt
mount -t vfat -o loop ~/customiso/EFI/archiso/efiboot.img mnt
cp ~/customiso/arch/boot/x86_64/vmlinuz mnt/EFI/archiso/vmlinuz.efi
cp ~/customiso/arch/boot/x86_64/archiso.img mnt/EFI/archiso/archiso.img
sed -i "s/archisolabel=ARCH_201904/archisolabel=$iso_label cow_label=cow intel_iommu=on/" mnt/loader/entries/archiso-x86_64.conf
umount mnt
rm -r mnt