#!/bin/bash

arch-chroot squashfs-root << EOF

    chsh -s /bin/zsh 

    pacman-key --init &&
    pacman-key --populate archlinux

    #remove autologin
    rm /etc/systemd/system/getty@tty1.service.d/autologin.conf

    sed -i  s/CheckSpace/\#CheckSpace/ /etc/pacman.conf

    yes | pacman -Syu --force archiso linux memteste86+
    yes | pacman -S qemu libvirt ovmf \
       bridge-utils dhcp openssh \
       samba transmission-cli apache \
       pciutils xfsprogs cups \
       docker docker-compose \
       libnewt \
       nbd syslinux mkinitcpio-nfs-utils
    

    #Instala os pacotes AUR compilados
    for file in /opt/*.pkg.tar.xz; do 
        yes | pacman -U "$file";
        rm "$file"
    done;

    #Cria diretórios referente aos serviços de comp. De arquivos
    mkdir -p /share/{Download,Files,Media,ISO,timemachine}
    groupadd network
    chgrp network /share/{Download,Files,Media,ISO,timemachine}
    chmod -R 770 /share/{Download,Files,Media,ISO,timemachine}



    echo "archraid" > /etc/hostname
    ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
    hwclock --systohc
    sed -i 's/^#pt_BR.UTF-8/pt_BR.UTF-8/'  /etc/locale.gen
    echo "LANG=pt_BR.UTF-8" > /etc/locale.conf
    locale-gen

    sed -i "s/HOOKS=(base udev/HOOKS=(base udev bcache lvm2 memdisk archiso_shutdown archiso archiso_loop_mnt archiso_pxe_common archiso_pxe_nbd archiso_pxe_http archiso_pxe_nfs archiso_kms/" /etc/mkinitcpio.conf 
    sed -i "s/MODULES=()/MODULES=(bcache vfio vfio_iommu_type1 vfio_pci vfio_virqfd)/" /etc/mkinitcpio.conf

    systemctl enable dhcpcd netatalk samba sshd transmission httpd docker libvirtd webmin

    mkdir -p /var/spool/samba/ &&
    chmod 1777 /var/spool/samba/

    curl -s -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/cjuniorfox/archraid/master/sh_config/setup_netatalk.sh | bash -
    curl -s -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/cjuniorfox/archraid/master/sh_config/setup_samba.sh | bash -

    mkinitcpio -p linux
    LANG=C pacman -Sl | awk '/\[installed\]$/ {print $1 "/" $2 "-" $3}' > /pkglist.txt
    yes | pacman -Scc

    exit
EOF