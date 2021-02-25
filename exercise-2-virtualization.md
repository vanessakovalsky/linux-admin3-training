# Exercice 2 - Virtualisation

Cet exercice a pour objectifs : 
* de créer des machines virtuelles en utilisant KVM, libvirt et les outils virt*
* de créer ses premiers conteneurs docker 

## Virtualisation avec KVM et libvirt

### Installer KVM et les outils de gestions
* Les instructions de virtualisation doivent être activés dans le BIOS, on vérifie ça : 
```sh
grep -E 'svm|vmx' /proc/cpuinfo
```
* Les valeurs correspondent au capacités des processeurs :
* * vmx pour les processeurs intel
* * svm pour les processeurs AMD 

* Mettre à jour son sytème et installer les paquets KVM :
```sh
yum update -y
yum group install "Virtualization Host" "Virtualization Client"

yum -y install \
qemu-kvm \
dejavu-lgc-sans-fonts \
libguestfs-tools
```
* Démarrer le service libvirtd
```sh
systemctl enable libvirtd && systemctl start libvirtd
```
* Démarrer le service chronyd 
```sh
systemctl enable chronyd && systemctl start chronyd
```
* Démarrer le commutateur virtuel par défaut : 
```sh
virsh net-start default
virsh net-autostart default
```
* Vérifier le chargement du module kvm par le noyau : 
```sh
lsmod | grep kvm
```
* Vérifier que le service libvirt est bien démarré : 
```sh
systemctl status libvirtd
```
* On configure le réseau comme suit : 
Une interface bridge virbr0 192.168.122.1 est “natée” à l’interface physique. Le démon dnsmasq fournit le service DNS/DHCP.
(https://d33wubrfki0l68.cloudfront.net/5fe534dcd6a89683f028b35002c3446a82d3efce/e76b4/assets/images/linux/vn-08-network-overview.png)

```sh
ip add sh virbr0
ip route
iptables -t nat -L -n -v
cat /proc/sys/net/ipv4/ip_forward
```


### Création des VM et administration de base 

Il est possible d'utiliser soit un outil graphique (si un serveur X est présent sur la machine) soit un outil ligne de commande : 
* Voir la documentation de Red Hat pour l'outil graphique virt-manager : https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_and_managing_virtualization/getting-started-with-virtualization-in-rhel-8_configuring-and-managing-virtualization#creating-vms-and-installing-an-os-using-the-rhel-8-web-console_assembly_creating-virtual-machines 
* En commande on utilise l'utilitaire virsh. 
Voici quelques commandes utiles pour créer et gérer ses VM :
* * Démarrage d’un domaine : virsh start vm1
* * Arrêt d’un domaine : virsh shutdown vm1
* * Extinction d’un domaine (comme on retire une prise de courant, il ne s’agit pas d’effacer le domaine) : virsh destroy vm1
* * Pour retirer une VM de la gestion (le ou les disques associés persistent) : virsh undefine vm1
* * Pour retirer un domaine de la gestion (et en effaçant ses disques) : virsh undefine vm1 --remove-all-storage
* * Redémarrage d’un domaine : virsh reboot vm1
* * Informations détaillées sur un domaine : virsh dominfo vm1
* * Liste des domaines en fonction et éteints : virsh list --all
* * Démarrage automatique du domaine au démarrage de l’hôte : virsh autostart vm1
* * Désactiver l’activation au démarrage du domaine : virsh autostart vm1 --disable
* * Accéder à la console série (texte) du domaine : virsh console vm1
* * Accéder à la console graphique du domaine : virt-viewer  vm1


### Scripts d'installation

La commande qui permet de créer une machine virtuelle et de la lancer est virt-install. Cette commande peut utiliser de nombreux paramètres, ce qui fait qu'il est très pertinent d'utiliser des script. 
Une machine virtuelle est composée de deux éléments fondamentaux :
* fichier de définition de VM écrit en XMl
* disque virtuel

Les procédures de création ou de maj d'objets avec la commande virsh se font via la manipulation des définitions XML : 
* define / undefine
* destroy / start / autostart

#### Premier script

* On va créer un script qui créera des VM avec les caractèristiques suivantes :
* * RAM 1024/1 vCPU
* * HD 8Go (raw)
* * ttyS0
* * console vnc
* * Installation CD-ROM

```sh
#!/bin/bash
# vm-install1.sh

# local path to the iso
iso=/var/lib/iso/CentOS-7-x86_64-DVD-1611.iso

# Stop and undefine the VM
/bin/virsh destroy $1; /bin/virsh undefine $1 --remove-all-storage

# graphical console
# via local ISO
virt-install \
--virt-type kvm \
--name=$1 \
--disk path=/var/lib/libvirt/images/$1.img,size=8 \
--ram=1024 \
--vcpus=1 \
--os-variant=rhel7 \
--graphics vnc \
--console pty,target_type=serial \
--cdrom $iso
```
* Executer le script et vérifier que la vm a été créé

### Exportmanuel d'une VM

* Suspendre la VM d'origine.
```sh
virsh suspend vm1
```
* Créer le fichier xml :
```sh
virsh dumpxml vm1 > vm2.xml
```
* Editer le fichier et effectuer les actions suivantes :
* * retirer la valeur de id 
* * retirer le champ uuid
* * modifier le champ name
* * modifier la balise source file qui désigne l'emplacement du nouveau disque
* * modifier le chamm mac adress -> supprimer les balises entre </devices> et </domain>

* Copier le disque dédié : 
```sh
cp /var/lib/libvirt/images/vm1.img /var/lib/libvirt/images/vm2.img
```
* Intégrer la nouvelle machine et la démarrer
```sh
virsh define vm2.xml
virsh start vm2
```

### Clonage avec virt-clone

* Lister les vm !
```sh
virsh list
```
* Suspendre la vm pour pouvoir la clone 
```sh
virsh suspend vm1
```
* Cloner la VM : 
```sh
virt-clone \
--original vm1 \
--name vm2 \
--file /var/lib/libvirt/images/vm2.img
```
* Redémarrer la machine vm 1 : 
```sh
virsh resume vm1
```

### Création d'un dépôt d'image et utilisation pour démarrer une VM

#### Créer un miroir local
* Installer apache et l'activer
```sh
yum -y install httpd
systemctl enable httpd.service && systemctl start httpd.service
```
* Télécharger une image ISO :
```sh
mkdir -p /var/lib/iso
cd /var/lib/iso
wget https://centos.mirrors.ovh.net/ftp.centos.org/7/isos/x86_64/CentOS-7-x86_64-DVD-1611.iso
```
* Monter l'ISO
```sh
mount -o loop,ro CentOS*.iso /mnt
```
* Copier les fichiers dans le répertoire web
```sh
mkdir /var/www/html/repo/
cp -rp /mnt/* /var/www/html/repo/
chcon -R -t httpd_sys_content_t /var/www/html
```

#### Utiliser le miroir local  dans un script d'installation

* Voici un script qui créer une VM à partir du miroir local :
```sh
#!/bin/bash
# vm-install2.sh

# KVM Host IP
bridge=192.168.122.1

# Repo URL
mirror=https://$bridge/repo
#mirror=https://centos.mirrors.ovh.net/ftp.centos.org/7/os/x86_64
#mirror=https://ftp.belnet.be/ftp.centos.org/7/os/x86_64
#mirror=https://mirror.i3d.net/pub/centos/7/os/x86_64

# Stop and undefine the VM
/bin/virsh destroy $1; /bin/virsh undefine $1 --remove-all-storage

# graphical console, bridged
# via http repo
virt-install \
--virt-type kvm \
--name=$1 \
--disk path=/var/lib/libvirt/images/$1.img,size=8 \
--ram=1024 \
--vcpus=1 \
--os-variant=rhel7 \
--network bridge=virbr0 \
--graphics vnc \
--console pty,target_type=serial \
--location $mirror
```
* Lancer le script, une VM sera créé à partir du miroir local contenant l'ISO


## Manipulation de conteneurs Docker

### Installer docker :
https://github.com/vanessakovalsky/docker-training/blob/master/tp/tp1/tp1.md 

### Création de notre premier conteneur :

https://github.com/vanessakovalsky/docker-training/blob/master/tp/tp2/tp2.md

### Créer une image docker 

https://github.com/vanessakovalsky/docker-training/blob/master/tp/tp4/tp4.md 