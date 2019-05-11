#!/bin/bash

arch-chroot squashfs-root /bin/zsh << EOF

    pacman-key --init &&
    pacman-key --populate archlinux

    #remove autologin
    rm /etc/systemd/system/getty@tty1.service.d/autologin.conf

    yes | pacman -Syu --force archiso linux
    yes | pacman -S qemu libvirt ovmf \
       bridge-utils dhcp openssh \
       samba transmission-cli apache \
       pciutils xfsprogs cups \
       docker docker-compose \
       libnewt

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

    for file in /opt/*.pkg.tar.xz; do 
        yes | pacman -U "$file";
        rm "$file"
    done;

    sed -i "s/HOOKS=(base udev/HOOKS=(base udev lvm2 memdisk archiso_shutdown archiso archiso_loop_mnt archiso_pxe_common archiso_pxe_nbd archiso_pxe_http archiso_pxe_nfs archiso_kms/" /etc/mkinitcpio.conf 
    sed -i "s/MODULES=()/MODULES=(bcache vfio vfio_iommu_type1 vfio_pci vfio_virqfd)/" /etc/mkinitcpio.conf

    mkinitcpio -p linux
    LANG=C pacman -Sl | awk '/\[installed\]$/ {print $1 "/" $2 "-" $3}' > /pkglist.txt
    yes | pacman -Scc
    
    systemctl enable dhcpcd netatalk samba sshd transmission httpd docker libvirtd webmin

    mkdir -p /var/spool/samba/ &&
    chmod 1777 /var/spool/samba/f
    exit
EOF