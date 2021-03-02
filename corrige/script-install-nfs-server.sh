#!/bin/bash

# Installation des outils nfs et démarrage du service

dnf install nfs-utils
systemctl start nfs-server.service
systemctl enable nfs-server.service

# Création du FS à exporter et à partager 

mkdir -p  /mnt/nfs_shares/{Human_Resource,Finance,Marketing}
mkdir  -p /mnt/backups

# Ajouter les dosssier au fichier d'exports

echo "/mnt/nfs_shares/Human_Resource  	*/24(rw,sync)\n
/mnt/nfs_shares/Finance			*/24(rw,sync)\n
/mnt/nfs_shares/Marketing		*/24(rw,sync)\n
/mnt/backups				*/24(rw,sync,no_all_squash,root_squash)" >> /etc/exports

# Mettre à jour l'export avec les dossiers que l'on vient d'ajouter

exportfs -arv 

# Ouvrir les service dans le firewall 

firewall-cmd --permanent --add-service=nfs
firewall-cmd --permanent --add-service=rpc-bind
firewall-cmd --permanent --add-service=mountd
firewall-cmd --reload

