arch-chroot squashfs-root << EOF
  yes | pacman -S xorg-xdm openbox xorg virt-manager xterm
  systemctl enable xdm.service
  echo ‘openbox’ > ~/.xsession
  chmod +x ~/.xsession
  exit
EOF