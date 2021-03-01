#!bin/bash

# Créer un compte admin

useradd -m admin_toor
echo $1 | passwd --stdin admin_toor 

usermod -AG root, adm admin_toor

# Désactiver la connexion root à distance

sed 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# Configurer une connexion SSH (la passprhase correspond au deuxième argument passé au script)
ssh-keygen -t rsa -b 4096 -f /home/admin_toor/centos-key -P $2
# cp /home/admin_toor/centos-key.pub /var/www/html/

useradd -m ubuntu 
echo $3 | passwd --stdin ubuntu

ssh-copy-id -i $4 ubuntu@localhost

# Mettre en place un pare-feu

if [[ -a /usr/sbin/iptables ]]
    then 
        echo -e "Paquet iptables déjà installé \n";
else 
    yum install -y iptables;
fi;

iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT

# OU bien avec firewall-cmd
# firewall-cmd --zone=public --permanent --add-port=80/tcp

# Mettre en place une protection contre les intrusions en filtrant les adresses IP

if [[ -a /usr/sbin/fail2ban ]]
    then 
        echo -e "Paquet fail2ban déjà installé \n";
else 
    yum install -y fail2ban;
fi;

service fail2ban start

# Mettre en place une sauvegarde

tar -czvf backup.tar.gz /var/www/html/*
scp backup.tar.gz centos@ubuntu:/home/ubuntu/backup 

# Mettre à jour son système et les applications et automatiser la mise à jour. 

crtonab -l ; echo "à 2 * * * yum update --security" | crontab -