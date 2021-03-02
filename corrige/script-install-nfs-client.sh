#!/bin/bash

# Installation des outils en fonction du type de distribution 

if [ "" == "`which nfs4-acl-tools`" ];
    then echo "nfs4-acl-tools Not Found";
        if [ -n "`which apt-get`" ];
            then apt-get install -y nfs-common nfs4-acl-tools ;
        elif [ -n "`which yum`" ];
            then dnf -y install nfs-utils nfs4-acl-tools ;
        fi ;
fi;

# Créer un dossier pour monter le FS NFS distant et mouter le en tant que FS 
# $1 = adresse IP du serveur NFS à passer en paramètre au script

mkdir -p /mnt/backups
mount -t nfs  $1:/mnt/backups /mnt/backups

# Rendre persistant le montage

echo "$1:/mnt/backups     /mnt/backups  nfs     defaults 0 0">>/etc/fstab