# Exercice 1 - Déploiement de serveurs et de poste de travail

Cet exercice a pour objectifs :
* De déployer un serveur PXELinux et d'installer des machines à partir de ce serveur
* D'automatiser l'installation avec des fichiers Kickstart
* De cloner une machine avec clonezilla
* (D'utiliser LTSP pour utiliser des machines à distances)



## Déployer un serveur PXELinux et d'installer des machines à partir de ce serveur

Cet exercice nécessite la création de 2 VM et l'installation de CentOs ou d'une autre distribution sur chacune des VM. Les commandes sont données à titre d'exemple sous Centos 8. 

### Installation du Repo :
* Création d'un dossier pour placer les images CentOS 
```sh
[root@centos-8 pxelinux]# mkdir /images
```
* Monter un disque ISO de Centos sur la VM dans le dossier mount : 
```sh
[root@centos-8 ~]# mount /dev/sr0 /mnt
```
* Copier l'ensemble des fichiers:
```sh
[root@centos-8 ~]# cp -apr /mnt/* /images/
```
* Copier également les fichiers cachés nécessaire à l'installation : 
```sh
[root@centos-8 ~]# cp -apr /mnt/.discinfo /mnt/.treeinfo /images/
```
* Vérifier le contenu du dossier : 
```sh
[root@centos-8 ~]# ls -al /images/
total 92
drwxr-xr-x   7 root root  4096 Apr 19 20:33 .
dr-xr-xr-x. 33 root root  4096 Apr 19 19:57 ..
dr-xr-xr-x   4 root root  4096 Oct 15  2019 AppStream
dr-xr-xr-x   4 root root  4096 Oct 15  2019 BaseOS
-r--r--r--   1 root root    60 Apr 19 20:33 .discinfo
dr-xr-xr-x   3 root root  4096 Oct 15  2019 EFI
-r--r--r--   1 root root  8266 Oct 15  2019 EULA
-r--r--r--   1 root root  1455 Oct 15  2019 extra_files.json
-r--r--r--   1 root root 18092 Oct 15  2019 GPL
dr-xr-xr-x   3 root root  4096 Oct 15  2019 images
dr-xr-xr-x   2 root root  4096 Oct 15  2019 isolinux
-r--r--r--   1 root root   103 Oct 15  2019 media.repo
-r--r--r--   1 root root  1669 Oct 15  2019 RPM-GPG-KEY-redhat-beta
-r--r--r--   1 root root  5134 Oct 15  2019 RPM-GPG-KEY-redhat-release
-r--r--r--   1 root root  1796 Oct 15  2019 TRANS.TBL
-r--r--r--   1 root root  1566 Apr 19 20:33 .treeinfo
```

### Installer et configurer le serveur TFTP

* Installer tftp et xinetd à l'aide de dnf : 
```sh
[root@centos-8 ~]# dnf install tftp-server xinetd -y
```
* Afficher le contenu du fichier de service de tftp
```sh
root@centos-8 pxelinux.cfg]# cat /usr/lib/systemd/system/tftp.service
[Unit]
Description=Tftp Server
Requires=tftp.socket
Documentation=man:in.tftpd

[Service]
ExecStart=/usr/sbin/in.tftpd -s /var/lib/tftpboot
StandardInput=socket

[Install]
Also=tftp.socket
```
* Démarrer le service tftp :
```sh
root@centos-8 pxelinux.cfg]# systemctl enable tftp.service --now
Created symlink /etc/systemd/system/sockets.target.wants/tftp.socket → /usr/lib/systemd/system/tftp.socket.
```
* Vérifier que le statut du socket tftp :
```sh
[root@centos-8 ~]# systemctl status tftp.socket
● tftp.socket - Tftp Server Activation Socket
   Loaded: loaded (/usr/lib/systemd/system/tftp.socket; enabled; vendor preset: disabled)
   Active: active (listening) since Sun 2020-04-19 19:32:40 IST; 7h ago
   Listen: [::]:69 (Datagram)
   CGroup: /system.slice/tftp.socket

Apr 19 19:32:40 centos-8.example.com systemd[1]: Listening on Tftp Server Activation Socket.
```

### Configurer le démarrage du serveur de boot PXE

Nousavons besoin de pouvioir démarrer les images Linux avec une configuration minimum depuis le serveur PXE;. Cela est fait en utilisant initrd et vmlinuz. 
* Créer un répertoire pour stocker les images PXE qui permettent de booter :
```sh
[root@centos-8 ~]# mkdir -p /var/lib/tftpboot/pxelinux
```

#### Extraire syslinux-tftpboot

* Sur RHEL/Centos8, le fichier pxelinux fait partie du rmp sylsinux-tftpboot, nous pouvons donc copier ce fichier depuis l'ISO vers un dossier temporaire :
```sh
[root@centos-8 ~]# cp /mnt/BaseOS/Packages/syslinux-tftpboot-6.04-4.el8.noarch.rpm /tmp/
```
* Extraire le rpm syslinux-tftpboot pour ne récupérer que les fichiers nécessaires :
```sh
[root@centos-8 ~]# cd /tmp/
[root@centos-8 tmp]# rpm2cpio syslinux-tftpboot-6.04-4.el8.noarch.rpm | cpio -idm
```
* Copier les fichier pxelinux.0 et ldlinux.c32 dans le dossier pxelinux crée, car ils sont requis pour configurer le serveur de boot PXE
```sh
root@centos-8 tmp]# cp /tmp/tftpboot/ldlinux.c32 /var/lib/tftpboot/pxelinux/
[root@centos-8 tmp]# cp /tmp/tftpboot/pxelinux.0 /var/lib/tftpboot/pxelinux/
```

#### Copier initrd et vmlinuz
* Nous avons aussi besoin d'images boot PXE qui sont dans le dossier isolinux de l'image ISO. Nous pouvons les copier depuis le dossier /images qui contient une copie de notre image vers le dossier pxelinux :
```sh
[root@centos-8 tmp]# cp /images/isolinux/initrd.img /var/lib/tftpboot/pxelinux/
[root@centos-8 tmp]# cp /images/isolinux/vmlinuz /var/lib/tftpboot/pxelinux/
```
* Lister les fichiers images de PXE boot :
```sh
root@centos-8 tmp]# ls -l /var/lib/tftpboot/pxelinux/
total 58880
-r--r--r-- 1 root root 62248424 Apr 19 19:14 initrd.img
-rw-r--r-- 1 root root   116096 Apr 19 19:47 ldlinux.c32
-rw-r--r-- 1 root root    42821 Apr 19 19:01 pxelinux.0
-r-xr-xr-x 1 root root  8106848 Apr 19 19:14 vmlinuz
```
* Aller dans le dossier pxelinux :
```sh
[root@centos-8 tmp]# cd /var/lib/tftpboot/pxelinux
```

#### Créer un menu Boot :
* Nous allons créer un serveur qui permet l'installation de plusieurs images. Nous avons donc besoin d'un menu de boot qui permet à l'utilisateur de choisir quelle image il souhaite installer. 
* Pour cela nous créons un fichier boot.msg dans /var/lib/tftpboot/pxelinux qui contient le contenu suivant :
```sh
Welcome to the installation of "My Linux Server" !
Centos 8.1 (x86_64)
Version: 1.0
Architecture: x86_64

To start the installation enter :
    '1', '2' and press .

Available boot options:

  1 - Install Centos 8.1
  2 - Boot from Harddisk (this is default)

Have a lot of fun...
```

#### Créer unu fichier de configuration PXE

* Une fois que le client a trouver et exécuter pxelinux.0, il est défini en dur de chercher un fichier dans le dossier pxelinux.cfg/ à l'endroit ou se trouve le pxelinux.0
* Le nom de ces fichiers est très important. Il définit l'ordre de recherche du fichier :
* * Adresse MAC dans sa forme 01-xx-xx-xx-xx-xx-xx
* * Adresse IP 
* * "default" 
* Créer le dossier pxelinux.cfg :
```sh
[root@centos-8 ~]# mkdir /var/lib/tftpboot/pxelinux/pxelinux.cfg
```
* Créer le fichier de configuration default :
```sh
root@centos-8 ~]# cat /var/lib/tftpboot/pxelinux/pxelinux.cfg/default
timeout 600
display boot.msg
default 1
prompt  1

label 1
  menu label ^Install Centos 8
  kernel vmlinuz
  append initrd=initrd.img showopts ks=nfs:10.10.10.12://ks/kickstart.conf 

label 2
  menu label Boot from ^local drive
  localboot 0x80

menu end
```
* Dans cet exemple il a 2 label basé sur le Boot Menu : 
* * label 1 : Celui utilisé pour installé Centos 8
* * label 2 : pour continuer à démarrer sur le disque dur
* * label2 est l'option par défaut qui est selectionné si l'utilisateur n'a pas choisi au bout de la valeur du timeout. 
* * On utilisera un serveur NDS pour configurer le serveur kickstart 
* * Le fichier kickstart sera dans un dossier /ks 

* Vérifiez que le fichier de configuration PXE a les droit de lecture pour l'utilisateur "autre" :
```sh
[root@centos-8 ~]# ls -l /var/lib/tftpboot/pxelinux/
total 68880
-rw-r--r-- 1 root root      325 Apr 19 19:10 boot.msg
-r--r--r-- 1 root root 62248424 Apr 19 19:14 initrd.img
-rw-r--r-- 1 root root   116096 Apr 19 19:47 ldlinux.c32
-rw-r--r-- 1 root root    42821 Apr 19 19:01 pxelinux.0
drwxr-xr-x 2 root root     4096 Apr 20 01:47 pxelinux.cfg
-r-xr-xr-x 1 root root  8106848 Apr 19 19:14 vmlinuz

[root@centos-8 ~]# ls -l /var/lib/tftpboot/pxelinux/pxelinux.cfg/default
-rw-r--r-- 1 root root 307 Apr 20 01:47 /var/lib/tftpboot/pxelinux/pxelinux.cfg/default
```

### Installer et configurer le serveur DHCP
Il est également possible d'utiliser DNSMASQ pour assigner des adresse IP mais nous utilisons un serveur DHCP dans cet exemple pour réaliser une installation de Linux basée sur le serveur. 
* Installer le serveur dhcp :
```sh
[root@centos-8 pxelinux.cfg]# dnf install dhcp-server -y
```
* Configurer le serveur DHCP avec la configuration suivante :
```sh
root@centos-8 pxelinux.cfg]# cat /etc/dhcp/dhcpd.conf

allow bootp;
allow booting;
max-lease-time 1200;
default-lease-time 900;
log-facility local7;

option ip-forwarding    false;
option mask-supplier    false;

   subnet 10.10.10.0 netmask 255.255.255.0 {

       option  routers   10.10.10.1;
       option  domain-name-servers  127.0.0.1;
       range 10.10.10.100 10.10.10.140;
       next-server 10.10.10.12;
       filename "pxelinux/pxelinux.0";
   }
```
* * Le nom du fichier pxe est défini avec la clé `filename` . Puisque nous utilisons tdtp qui est configuré pour utilisé /var/lib/tftp par défaut, nous donnons seulement la localisation pxelinux/pxelinux.0
* * `next-server` définit l'adresse IP du serveur TFTP
* * `range` est utilisé pour assigner les adresses IP pour les requêtes DHCP
* Démarrer le service dhcp : 
```sh
[root@centos-8 pxelinux.cfg]# systemctl enable dhcpd --now
Created symlink /etc/systemd/system/multi-user.target.wants/dhcpd.service → /usr/lib/systemd/system/dhcpd.service.
```
* Vérifier que le service fonctionne 
```sh
[root@centos-8 ~]# systemctl status dhcpd
● dhcpd.service - DHCPv4 Server Daemon
   Loaded: loaded (/usr/lib/systemd/system/dhcpd.service; enabled; vendor preset: disabled)
   Active: active (running) since Sun 2020-04-19 19:45:45 IST; 6h ago
     Docs: man:dhcpd(8)
           man:dhcpd.conf(5)
 Main PID: 30897 (dhcpd)
   Status: "Dispatching packets..."
    Tasks: 1 (limit: 26213)
   Memory: 5.1M
   CGroup: /system.slice/dhcpd.service
           └─30897 /usr/sbin/dhcpd -f -cf /etc/dhcp/dhcpd.conf -user dhcpd -group dhcpd --no-pid
```

L'installation et la configuration du serveur PXE Linux est maintenant terminé, passons à la partie automatisation de l'installation avec Kickstart avant de faire nos tests.  


## Automatiser l'installation avec des fichiers Kickstart
Pour configurer le serveur kickstart, nous avons besoin d'un fichier kickstart. Chaque installationd e RHEL ou de CentOs crée un ficher kickstart par défaut qui est dans le dossier home de l'utilisateur root, par exemple :  /root/anaconda-ks.cfg .
On peut utilsier ce fichier pour configurer le serveur kickstart ou utiliser le générateur en ligne de Red hat : https://access.redhat.com/labsinfo/kickstartconfig 

### Installer et configurer le serveur kickstart

* Créer le dossier /ks pour stocker nos fichiers kickstart :
```sh
[root@centos-8 pxelinux.cfg]# mkdir /ks
```
* Copier le contenu de anaconda-ks.cfg et le renommer dans /ks/kickstart.conf
```sh
[root@centos-8 pxelinux.cfg]# cp /root/anaconda-ks.cfg /ks/kickstart.conf
```
* S'assurer que le ficheir kickstart est accessible en lecture par les autres utilsiateurs et que le dossier ks a les permissions de lecture et d'éxécution pour les autres : 
```sh
[root@centos-8 ~]# ls -l /ks/kickstart.conf
-rw-r--r-- 1 root root 1688 Apr 19 20:55 /ks/kickstart.conf
```
* Exemple de contneu de fichier de configuration Kickstart :
```sh
[root@centos-8 pxelinux]# cat /ks/kickstart.conf

#version=RHEL8
ignoredisk --only-use=sda

# Partition clearing information
clearpart --all

# Use text install
text

# Create APPStream Repo
repo --name="AppStream" --baseurl=file:///run/install/repo/AppStream

# Use NFS Repo
nfs --server=10.10.10.12 --dir=/images/

# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'

# System language
lang fr_FR.UTF-8

# Network information
network  --bootproto=dhcp --device=eth0 --ipv6=ignore --activate
network  --bootproto=dhcp --device=eth1 --onboot=off --ipv6=ignore --activate
network  --hostname=centos8-4.example.com

# Root password
rootpw --iscrypted $6$w7El/FYx9mbTG6x9$Te.Yg6dq0TsQwGpdSjeDGSw4J9ZBAkLXzT9ODMV7I7lHvX3n5.9PCS4jIkS2GbVLZOpVRLvrua3wwbwA.cfWX.

# Run the Setup Agent on first boot
firstboot --enable

# Do not configure the X Window System
skipx

# System services
services --enabled="chronyd"

# System timezone
timezone Europe/Paris --isUtc

# Reboot after installation completes
reboot

# Disk partitioning information
autopart --type=plain --fstype=ext4

# Packages to be installed
%packages
@^virtualization-host-environment
kexec-tools

%end

%addon com_redhat_kdump --enable --reserve-mb='auto'
%end

%anaconda
pwpolicy root --minlen=6 --minquality=1 --notstrict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=1 --notstrict --nochanges --emptyok
pwpolicy luks --minlen=6 --minquality=1 --notstrict --nochanges --notempty
%end
```
### Installer et configurer le serveur NFS 

Il est possible d'utiliser d'autre service comme HTTPS ou FTP pour partager le contenu du repo et du kickstart pour effectuer des installations sur le réseau. Ici nous avons fait le chois de NFS. Voici un article (en anglais) pour utiliser HTTPE avec RHEL/CentOs 7 :  https://www.golinuxcloud.com/configure-pxe-boot-server-centos-redhat-7-linux/ 

* Installer nfs-utils
```sh
[root@centos-8 ~]# dnf -y install nfs-utils
```
* Les deux dossier à partacher pour le serveur Linux kickstart sont : 
* * /ks qui contient les fichiers de configurations
* * /images qui contient le contenu de l'ISO pour l'installation
* Créer le contenu du fichier d'export :
```sh
[root@centos-8 ~]# cat /etc/exports
/ks     *(ro,sync,no_root_squash)
/images *(ro,sync,no_root_squash)
```
* Relancer l'export des partages :
```sh
[root@centos-8 ~]# exportfs -r
```
* Afficher les partages disponibles :
```sh
[root@centos-8 ~]# exportfs -v
/ks             (sync,wdelay,hide,no_subtree_check,sec=sys,ro,secure,no_root_squash,no_all_squash)
/images         (sync,wdelay,hide,no_subtree_check,sec=sys,ro,secure,no_root_squash,no_all_squash)
```
* Activer le service NFS : 
```sh
[root@centos-8 ~]# systemctl enable nfs-server --now
```
* Vérifier que le serveur nfs fonctionne 
```sh
[root@centos-8 ~]# systemctl status nfs-server
● nfs-server.service - NFS server and services
   Loaded: loaded (/usr/lib/systemd/system/nfs-server.service; enabled; vendor preset: disabled)
  Drop-In: /run/systemd/generator/nfs-server.service.d
           └─order-with-mounts.conf
   Active: active (exited) since Sun 2020-04-19 19:49:17 IST; 6h ago
  Process: 31119 ExecStopPost=/usr/sbin/exportfs -f (code=exited, status=0/SUCCESS)
  Process: 31117 ExecStopPost=/usr/sbin/exportfs -au (code=exited, status=0/SUCCESS)
  Process: 31116 ExecStop=/usr/sbin/rpc.nfsd 0 (code=exited, status=0/SUCCESS)
  Process: 31144 ExecStart=/bin/sh -c if systemctl -q is-active gssproxy; then systemctl reload gssproxy ; fi (code=exited, status=0/SUCCESS)
  Process: 31132 ExecStart=/usr/sbin/rpc.nfsd (code=exited, status=0/SUCCESS)
  Process: 31131 ExecStartPre=/usr/sbin/exportfs -r (code=exited, status=0/SUCCESS)
 Main PID: 31144 (code=exited, status=0/SUCCESS)

Apr 19 19:49:17 centos-8.example.com systemd[1]: Starting NFS server and services...
Apr 19 19:49:17 centos-8.example.com systemd[1]: Started NFS server and services.
```

### Tester l'installation depuis un boot PXE 
* Lancer la machine à installer et accèder aux options de boot
[https://www.golinuxcloud.com/wp-content/uploads/2020/04/pxe-1.jpg]
* Choisir un démarrage sur le réseau 
[https://www.golinuxcloud.com/wp-content/uploads/2020/04/pxe-2.jpg]
* Dans l'écran suivant vous devriez voir les message indiquant que la machine démarrer sur PXE et contacte le serveur DHCP pour obtenir une adresse IP :
[https://www.golinuxcloud.com/wp-content/uploads/2020/04/pxe-3.jpg]
* Une fois l'adressse IP obtenu, PXE cherche les fichiers de boot. Puis vous affiche le menu de boot
[https://www.golinuxcloud.com/wp-content/uploads/2020/04/pxe-4.jpg]
* Si tout est ok, l'installation devrait se lancer et vous devriez accéder à l'écran de login après l'installation : 
[https://www.golinuxcloud.com/wp-content/uploads/2020/04/pxe-5.jpg]


## Optionnel - Cloner une disque avec clonezilla
* Cet exercice permet de cloner un disque sur un support externe. 
* Vous pouvez le faire à partir de cet exemple : https://lecrabeinfo.net/creer-une-image-disque-avec-clonezilla.html 

## Optionnel Utiliser LTSP pour utiliser des machines à distance
* Cet exercice nécessite du matériel spécifique il est donc à faire en dehors de la formation avec votre propre matériel : 
https://gebull.org/ltsp-la-solution-legere-pour-les-reseaux-lourdes/ 