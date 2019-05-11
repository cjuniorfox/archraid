#!/bin/bash

#Label e cow
sed -i "s/archisolabel=ARCH_201904/archisolabel=$iso_label cow_label=cow intel_iommu=on/" ../../arch/boot/syslinux/archiso_sys.cfg
#monta EFI para modificar strings
mkdir mnt
mount -t vfat -o loop 
cd ~/customiso
yes | pacman -S cdrtools libisoburn
genisoimage -l -r -J -V "ARCHRAID_20190507" -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table -c isolinux/boot.cat -o ../arch-custom.iso ./


xorriso -as mkisofs \
       -iso-level 3 \
       -full-iso9660-filenames \
       -volid "${iso_label}" \
       -eltorito-boot isolinux/isolinux.bin \
       -eltorito-catalog isolinux/boot.cat \
       -no-emul-boot -boot-load-size 4 -boot-info-table \
       -isohybrid-mbr ~/customiso/isolinux/isohdpfx.bin \
       -output arch-custom_efi.iso \
       -eltorito-alt-boot \
       -e EFI/archiso/efiboot.img \
       -no-emul-boot -isohybrid-gpt-basdat \
       ~/customiso