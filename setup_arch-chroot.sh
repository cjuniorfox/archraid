#!/bin/bash
pacman-key --init &&
pacman-key --populate archlinux

hwclock --systohc
sed -i 's/^#pt_BR.UTF-8/pt_BR.UTF-8/'  /etc/locale.gen
sed -i 's/^#en_US.UTF-8/en_US.UTF-8/'  /etc/locale.gen

echo "LANG=en_US.UTF-8" > /etc/locale.conf
locale-gen

sed -i  s/CheckSpace/\#CheckSpace/ /etc/pacman.conf

pacman -Syu --noconfirm archiso linux memtest86+ \
   fuse3 sudo gdisk \
   qemu libvirt ovmf openbsd-netcat \
   bridge-utils openssh networkmanager dnsmasq \
   samba transmission-cli nginx \
   pciutils xfsprogs cups \
   docker docker-compose \
   libnewt \
   nbd syslinux mkinitcpio-nfs-utils \
   perl-socket6 perl-net-ssleay \
   vim \
   base-devel git make go

#Dependência para webvirtmgr
pacman -S libvirt-python2 --noconfirm

groupadd sudo
chmod +w /etc/sudoers
sed -i "s/# %sudo/%sudo/" /etc/sudoers

echo "___aur ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

#Installing yay for AUR packages
for file in /opt/*.pkg.tar.xz; do
    echo "Instalando $file";
    pacman -U --noconfirm "$file" &&
    rm "$file"
done;
#Installing aur packages
useradd -ms /bin/bash ___aur
usermod -aG sudo ___aur
sudo -u ___aur yay -S bcache-tools snapraid mergerfs webmin webvirtmgr-git netatalk --noconfirm
userdel ___aur;
sed -i "s/___aur ALL=(ALL) NOPASSWD: ALL//" /etc/sudoers
rm -r /home/___aur

#Configuration of webvirtmgr
systemctl enable supervisord
#To access VNC console you need to enable the NoVNC proxy.
systemctl enable webvirtmgr-novnc
#Configure nginx to proxy webvirtmgr
mkdir /etc/nginx/sites-{available,enabled} 
sed -i 's/^    server/    include sites-enabled\/*;\n    server/g' /etc/nginx/nginx.conf
cp /etc/nginx/conf.d/webvirtmgr.nginx.conf.sample /etc/nginx/sites-available/webvirtmgr &&
  ln -s /etc/nginx/sites-available/webvirtmgr /etc/nginx/sites-enabled/webvirtmgr
#webvirtmgr authentication
sed -i "s/#auth_unix_rw/auth_unix_rw/" /etc/libvirt/libvirtd.conf

#Cria diretórios referente aos serviços de comp. De arquivos
mkdir -p /share/{Download,Files,Media,ISO,timemachine}
groupadd network
chgrp network /share/{Downloads,Games,Files,Media,ISO,timemachine}
chmod -R 770 /share/{Downloads,Games,Files,Media,ISO,timemachine}

echo "$1" > /etc/hostname
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime

sed -i "s/HOOKS=(base udev/HOOKS=(base udev bcache lvm2 memdisk archiso_shutdown archiso archiso_loop_mnt archiso_pxe_common archiso_pxe_nbd archiso_pxe_http archiso_pxe_nfs archiso_kms modconf/" /etc/mkinitcpio.conf 
sed -i "s/MODULES=()/MODULES=(bcache vfat squashfs ext4 xfs dm_mod xhci-hcd vfio_pci vfio vfio_iommu_type1 vfio_virqfd)/" /etc/mkinitcpio.conf

systemctl enable NetworkManager \
 netatalk smb avahi-daemon sshd transmission nginx \
 docker libvirtd virtlogd.socket webmin supervisord

mkdir -p /var/spool/samba/ &&
  chmod 1777 /var/spool/samba/

curl -sL "https://raw.githubusercontent.com/cjuniorfox/archraid/master/sh_config/afp.conf" > /etc/afp.conf

#Setting-up OVMF (UEFI)
cat << EOF >> /etc/libvirt/qemu.conf
nvram = [
  "/usr/share/ovmf/x64/OVMF_CODE.fd:/usr/share/ovmf/x64/OVMF_VARS.fd"
]
EOF
mkdir -p /var/spool/samba/ &&
  chmod 1777 /var/spool/samba/ &&
  curl -sL "https://raw.githubusercontent.com/cjuniorfox/archraid/master/sh_config/smb.conf" > /etc/samba/smb.conf

curl -sL "https://raw.githubusercontent.com/cjuniorfox/archraid/master/setup_arch-chroot-gui.sh" | bash -

#Snapraid configuration example:
curl -sSL 'https://raw.githubusercontent.com/amadvance/snapraid/master/snapraid.conf.example' -o /etc/snapraid.conf

mkinitcpio -p linux;
LANG=C pacman -Sl | awk '/\[installed\]$/ {print $1 "/" $2 "-" $3}' > /pkglist.txt;
yay -Scc --noconfirm;

#########################################################################################################################################################################################################################
# Webvirtmgr. After instal, run this post installation commands:
#
#  PYTHONPATH=/usr/lib/webvirtmgr/lib python2 /usr/lib/webvirtmgr/manage.py syncdb
#  chown webvirtmgr:webvirtmgr /usr/lib/webvirtmgr/webvirtmgr/local/.secret_key_store /usr/lib/webvirtmgr/webvirtmgr.sqlite3 /usr/lib/webvirtmgr # temporary, see https://github.com/retspen/webvirtmgr/issues/391
#  PYTHONPATH=/usr/lib/webvirtmgr/lib python2 /usr/lib/webvirtmgr/manage.py collectstatic
#
#
#
