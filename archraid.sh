#!/bin/bash
#aumentando espaço live
#mount -o remount,size=3G /run/archiso/cowspace

yes | pacman -Sy pacman-contrib
#cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
curl -s "https://www.archlinux.org/mirrorlist/?country=BR&protocol=http&protocol=https&ip_version=4&use_mirror_status=on" |
   sed -e 's/^#Server/Server/' -e '/^#/d' |
   rankmirrors -n 5 - > /etc/pacman.d/mirrorlist

#instalar pacotes pacman necessários para compilação
# [perl-encode-detect] - perl-module-build
# [Webmin]   - perl-net-ssleay 
# [Netatalk] - avahi python2 dbus-glib python2-dbus
echo -e "\ny" | pacman -S base-devel perl-module-build perl-net-ssleay avahi python2 dbus-glib python2-dbus git

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

~/customiso/arch/x86_64

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


















#criando ramdisk para chroot
if ! [ -d $HOME/LIVE_BOOT ]; then
   mkdir -p $HOME/LIVE_BOOT/{chroot,image} || exit;
fi;
#mount -t tmpfs -o size=2G new_ram_disk $HOME/LIVE_BOOT/chroot

#instalando última versão do Arch linux no ramdisk
pacstrap $HOME/LIVE_BOOT/chroot base syslinux

#instalar pacotes AUR necessarios para compilação
pacman -S --needed base-devel --noconfirm

#instalar pacotes pacman necessários para compilação
# [perl-encode-detect] - perl-module-build
# [Webmin]   - perl-net-ssleay 
# [Netatalk] - avahi python2 dbus-glib python2-dbus
yes | pacman -S perl-module-build perl-net-ssleay avahi python2 dbus-glib python2-dbus

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
declare -a aurlist=("webmin" "mergerfs" "snapraid" "netatalk" "bcache-tools") &&
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
        cp "$instPkg" /opt/;
    done;
done;

#Copia o Mirror para a maquina chroot
cp /etc/pacman.d/mirrorlist $HOME/LIVE_BOOT/chroot/etc/pacman.d/mirrorlist

#Acessa o target instalado e instala localmente ferramentas adicionais.
#arch-chroot $HOME/LIVE_BOOT/chroot <<EOF
echo -e "senha123\nsenha123" | (passwd root)
echo "archraid" > /etc/hostname
#chown root /usr/local/bin/snapraid &&
#  chown root /etc/snapraid.conf &&
#  chmod +x /usr/local/bin/snapraid
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc
sed -i 's/^#pt_BR.UTF-8/pt_BR.UTF-8/'  /etc/locale.gen
echo "LANG=pt_BR.UTF-8" > /etc/locale.conf
mkinitcpio -p linux

#Instala os pacotes AUR compilados
for file in /opt/*.pkg.tar.xz; do 
    yes | pacman -U "$file";
    rm "$file"
done;

#Instala demais programas necessários
yes | pacman -Sy \
  squashfuse \
  dhcp \
  openssh \
  xfsprogs \
  gdisk \
  pciutils \
  vim \
  libnewt \
  qemu \
  libvirt \
  libvirt-python \
  bridge-utils \
  ovmf \
  samba \
  cups \
  transmission-cli \
  docker \
  docker-compose \
  apache

#Cria diretórios referente aos serviços de comp. De arquivos
mkdir -p /share/{Download,Files,Media,ISO,timemachine}

groupadd network &&
    chgrp network /share/{Download,Files,Media,ISO,timemachine}
chmod -R 770 /share/{Download,Files,Media,ISO,timemachine}

#configuracao dos compartilhamentos

#Samba
mkdir -p /var/spool/samba/ && \

    chmod 1777 /var/spool/samba/ && \
    echo "[global]
    workgroup = WORKGROUP
    server string = Samba Server %v
    security = user
    map to guest = bad user
    dns proxy = no
    
    [homes]
       comment = Home Directories
       browseable = no
       valid users = %S
       writable = yes
       create mask = 0700
       directory mask = 0700
    
    [Download]
      comment = Download
      path = /share/Download
      valid users = @network
      force group = network
      create mask = 0660
      directory mask = 0771
      writable = yes

    [ISO]
      comment = ISOs 
      path = /share/ISO
      valid users = @network
      force group = network
      create mask = 0660
      directory mask = 0771
      writable = yes

    [Media]
      comment = Music, Video and TV Shows
      path = /share/Media
      valid users = @network
      force group = network
      create mask = 0660
      directory mask = 0771
      writable = yes

    [Files]
      comment = Home Cloud
      path = /share/Files
      valid users = @network
      force group = network
      create mask = 0660
      directory mask = 0771
      writable = yes
      
    [printers]
      path = /var/spool/samba/
      printable = yes
    " > /etc/samba/smb.conf

#Netatalk
    echo "[Global]
       spotlight = yes
       dbus daemon = /usr/bin/dbus-daemon
       mimic model = RackMac
    
       [Homes]
          basedir regex = /home
   
       [Download]
          path = /share/Download

       [ISO]
          path = /share/ISO
   
       [Media]
          path = /share/Media
   
       [Files]
          path = /share/Files
   
       [My Time Machine Volume]
          path = /share/timemachine
          time machine = yes
          spotlight = no
          vol size limit = 512000
        " > /etc/afp.conf
sed -i "s/HOOKS=(base udev/HOOKS=(base udev memdisk archiso_shutdown archiso archiso_loop_mnt archiso_pxe_common archiso_pxe_nbd archiso_pxe_http archiso_pxe_nfs archiso_kms/" /etc/mkinitcpio.conf
sed -i "s/MODULES=()/MODULES=(vfio vfio_iommu_type1 vfio_pci vfio_virqfd)/" /etc/mkinitcpio.conf
mkinitcpio -p linux
rm -r /var/cache/pacman/*
EOF