#!/bin/bash

# Passer SELinux en mode permissive

sed -i 's/SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config
setenforce 0

# Installer les dépendances

dnf update -y
dnf install -y @php
dnf install -y @perl @httpd wget unzip glibc automake glibc-common gettext autoconf php php-cli gcc gd gd-devel net-snmp openssl-devel unzip net-snmp postfix net-snmp-utils

dnf groupinstall -y "Development Tools"

# Démarrer les service httpd et php-fpm

systemctl enable --now httpd php-fpm

# Télécharger Nagios

cd ~
export VER="4.4.6"
curl -SL https://github.com/NagiosEnterprises/nagioscore/releases/download/nagios-$VER/nagios-$VER.tar.gz | tar -xzf -

# Compiler le coeur de Nagios
cd nagios-$VER
./configure
make all

# Créer le user et le group

make install-groups-users
usermod -a -G nagios apache

# Installer Nagios coeur, le script init et les permissions sur les dossiers ainsi que les fichiers de configurations

make install
make install-daemoninit
make install-commandmode
make install-config

## Installer l'interface web

make install-webconf
make install-exfoliation

# Créer l'utilisateur web de Nagios

htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin
systemctl restart httpd

# Installer les plugins de Nagios 

cd ~
VER="2.3.3"
curl -SL https://github.com/nagios-plugins/nagios-plugins/releases/download/release-$VER/nagios-plugins-$VER.tar.gz | tar -xzf -
cd nagios-plugins-$VER
./configure --with-nagios-user=nagios --with-nagios-group=nagios
make
make install

# Vérifier l'installation et démarrer le service Nagios

usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg
systemctl  enable --now nagios

# Ouvrir le pare feu pour accéder au tableau de bord web de nagios
firewall-cmd --permanent  --add-service={http,https}
firewall-cmd --reload

echo "Vous pouvez acceder au tableau de bord web à l'adresse :  http:[IP/hostname]/nagios/"



