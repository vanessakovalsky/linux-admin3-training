# Exercice 3 - Sécurité indispensable

Cet exercice a pour obejctifs : 
* de permettre la connexion entre deux machines 
* de sécuriser les machines
* de manipuler le pare-feu local


## Consignes 

En binôme / trinôme, et en tenant compte des informations suivantes, fournir un script par machine permettant de configurer la sécurité sur chaque machine en prenant en compte les contraintes ci-dessous

* Créer deux VM une sous ubuntu et une sous CentOs
* Faites en sorte que les deux VM soient sécurisées
* Permettre dans les deux sens un accès SSH d'une VM à l'autre
* La VM CentOs hébergera un serveur web il faut donc que l'on puisse accéder à cette vm sur le port 80
* La VM Ubuntu ne servira que pour le développeur. Pas d'accès à part en SSH vers la machine CentOS

## Etapes à suivre
<details>
  <summary>Etapes à suivre</summary>
* Créer un compte admin
* Désactiver la connexion root locale et à distance
* Configurer une connexion SSH
* Mettre en place un pare-feu
* Mettre en place une protection contre les intrusions en filtrant les adresses IP
* Mettre en place une sauvegarde
* Mettre à jour son système et les applications et automatiser la mise à jour.   
</details>

## En pratique :

Voici quelques liens qui vous expliquent en pratique comment parvenir à sécuriser votre serveur Linux :

* https://www.remipoignon.fr/securiser-son-serveur-linux/
* https://blog.eleven-labs.com/fr/securiser-facilement-son-vps-en-quelques-etapes/ 
* https://docs.ovh.com/fr/dedicated/securiser-un-serveur-dedie/