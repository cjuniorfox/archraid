#!/bin/bash

    chsh -s /bin/zsh 

    pacman-key --init &&
    pacman-key --populate archlinux

    #remove autologin
    rm /etc/systemd/system/getty@tty1.service.d/autologin.conf

    sed -i  s/CheckSpace/\#CheckSpace/ /etc/pacman.conf

    yes | pacman -Syu --force archiso linux memtest86+
    yes | pacman -S fuse3 sudo \
       qemu libvirt ovmf \
       bridge-utils openssh networkmanager \
       samba transmission-cli nginx \
       pciutils xfsprogs cups \
       docker docker-compose \
       libnewt \
       nbd syslinux mkinitcpio-nfs-utils \
       perl-socket6 perl-net-ssleay \
       vim

    #pacotes para python2-django-auth-ldap
#    yes | pacman -S python2-django

    #pacotes para websockify (dependência do Webvirtmgr)
#    yes | pacman -S python-numpy

    #pacotes para Webvirtmgr
    yes | pacman -S libvirt \
      libvirt-python \
      qemu \
      bridge-utils \
      ebtables \
      dmidecode #\
#      python2-django \
#      python2-lockfile \
#      python2-gunicorn 
      
    #Instala os pacotes AUR compilados
    for file in /opt/*.pkg.tar.xz; do
        echo "Instalando $file";
        yes | pacman -U "$file";
        rm "$file"
    done;

#    #Webvirtmgr python2-django-auth-ldap
#    yes | pacman -S dmidecode dnsmasq ebtables libvirt-python python2 python2-django python2-gunicorn \
#     python2-lockfile python2-pip bridge-utils python-distribute python-numpy libvirt-python2 supervisor
#
#    #Webvirt depende de QEMU para compilar, sera compilado em ambiente chroot.


#    declare -a aurlist=( "websockify" "python2-django-auth-ldap" "webvirtmgr")  &&
#    for package in ${aurlist[@]}; do
#        cd /tmp ;
#        git clone "https://aur.archlinux.org/$package.git" ;
#        cd "$package" || exit;
#        chgrp nobody . &&
#        chmod g+ws . &&
#        setfacl -m u::rwx,g::rwx . &&
#        setfacl -d --set u::rwx,g::rwx,o::- . &&
#        sudo -u nobody makepkg ;
#        chmod -R 777 /usr/lib/python*
#        for instPkg in ./*.pkg.tar.xz; do
#            yes | pacman -U "$instPkg";
#        done;
#        chmod -R 755 /usr/lib/python*
#    done;

    #Cria diretórios referente aos serviços de comp. De arquivos
    mkdir -p /share/{Download,Files,Media,ISO,timemachine}
    groupadd network
    chgrp network /share/{Download,Games,Files,Media,ISO,timemachine}
    chmod -R 770 /share/{Download,Games,Files,Media,ISO,timemachine}



    echo "$1" > /etc/hostname
    ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
    chmod +w /etc/sudoers
    sed -i "s/# %sudo/%sudo/" /etc/sudoers
    hwclock --systohc
    sed -i 's/^#pt_BR.UTF-8/pt_BR.UTF-8/'  /etc/locale.gen
    sed -i 's/^#en_US.UTF-8/en_US.UTF-8/'  /etc/locale.gen

    echo "LANG=en_US.UTF-8" > /etc/locale.conf
    locale-gen

    sed -i "s/HOOKS=(base udev/HOOKS=(base udev bcache lvm2 memdisk archiso_shutdown archiso archiso_loop_mnt archiso_pxe_common archiso_pxe_nbd archiso_pxe_http archiso_pxe_nfs archiso_kms modconf/" /etc/mkinitcpio.conf 
    sed -i "s/MODULES=()/MODULES=(bcache vfat squashfs ext4 xfs dm_mod xhci-hcd vfio vfio_iommu_type1 vfio_pci vfio_virqfd)/" /etc/mkinitcpio.conf

    systemctl enable NetworkManager \
     netatalk smb avahi-daemon sshd transmission nginx \
     docker libvirtd virtlogd webmin supervisord

    mkdir -p /var/spool/samba/ &&
      chmod 1777 /var/spool/samba/

    curl -sL "https://raw.githubusercontent.com/cjuniorfox/archraid/master/sh_config/afp.conf" > /etc/afp.conf

    #Setting-up OVMF (UEFI)
    cat << EOF >> /etc/libvirt/qemu.conf
nvram = [
  "/usr/share/ovmf/x64/ovmf_x64.bin:/usr/share/ovmf/ovmf_vars_x64.bin"
]
EOF
    mkdir -p /var/spool/samba/ &&
      chmod 1777 /var/spool/samba/ &&
      curl -sL "https://raw.githubusercontent.com/cjuniorfox/archraid/master/sh_config/smb.conf" > /etc/smb.conf

    curl -sL "https://raw.githubusercontent.com/cjuniorfox/archraid/master/setup_arch-chroot-gui.sh" | bash -

    mkinitcpio -p linux;
    LANG=C pacman -Sl | awk '/\[installed\]$/ {print $1 "/" $2 "-" $3}' > /pkglist.txt;
    yes | pacman -Scc;