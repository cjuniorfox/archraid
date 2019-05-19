#!/bin/bash
  echo -e "\n\ny" | pacman -S xorg-xdm xorg-xinit xorg xterm xorg-xclock xorg-twm \
    firefox virt-manager \
  	font-bh-ttf ttf-dejavu ttf-liberation \
  	blackbox \
  	tigervnc
  	
#  systemctl enable xdm.service
  echo "exec blackbox" > ~/.xinitrc
  LANG=C pacman -Sl | awk '/\[installed\]$/ {print $1 "/" $2 "-" $3}' > /pkglist.txt
  yes | pacman -Scc

#Enable blackbox for VNC Session

  cat << EOF > ~/.vnc/xstartup
#!/bin/sh

unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec blackbox
EOF
