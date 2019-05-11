#!/bin/bash

    mkdir -p /var/spool/samba/ &&
    chmod 1777 /var/spool/samba/ &&
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
    exit
EOF
