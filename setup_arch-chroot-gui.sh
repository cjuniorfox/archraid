#!/bin/bash
  echo -e "\n\ny" | pacman -S xorg-xdm xorg-xinit xorg xterm xorg-xclock xorg-twm \
    firefox virt-manager \
  	font-bh-ttf ttf-dejavu ttf-liberation \
  	openbox  gnome-terminal \
  	
#  systemctl enable xdm.service
  echo "exec openbox-session" > ~/.xinitrc
  LANG=C pacman -Sl | awk '/\[installed\]$/ {print $1 "/" $2 "-" $3}' > /pkglist.txt
  yes | pacman -Scc