#!/bin/bash

  echo -e "\n\ny" | pacman -S xorg-xdm openbox xorg virt-manager xterm firefox
  systemctl enable xdm.service
  echo ‘openbox’ > ~/.xsession
  chmod +x ~/.xsession
  LANG=C pacman -Sl | awk '/\[installed\]$/ {print $1 "/" $2 "-" $3}' > /pkglist.txt
  yes | pacman -Scc