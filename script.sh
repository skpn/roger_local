#!/bin/bash

################################################################################
### packages update
################################################################################

echo script log file: /root/script_log.txt

exec &> >(tee -a "/root/script_log.txt")

echo "\n\nupdating packages\n\n"

sed -i 's/^deb cdrom/# deb cdrom/g' /etc/apt/sources.list

apt-get -y update
apt-get -y upgrade
apt-get -y install sudo
apt-get -y install vim

################################################################################
### user config
################################################################################

echo "\n\ncreating independant sudo user\n\n"

# creating user 'sudouser' in group sudo with no personnal info and no password
adduser --ingroup sudo --disabled-password --gecos "" sudouser

#giving a password to the user 'sudouser'
echo "sudouser:sudopwd" | chpasswd
#cp /etc/sudoers /etc/sudoers_cpy
#echo 'sudouser ALL=NOPASSWD:ALL' | EDITOR='tee -a' visudo

################################################################################
### network config
################################################################################

echo "\n\nconfiguring static IP rules\n\n"

ipaddr=$(ip addr show enp0s3 | awk '{ if ($1 == "inet") print $2}')
gateway=$(ip route show default | awk '{ print $3 }')
network_config_file=/etc/network/interfaces

# get the enp0s3 interface up automatically at boot
sed -i "s/iface enp0s3.*/auto enp0s3\\n&/" $network_config_file

# change the enp0s3 interface type from dhcp to static
sed -i "s/enp0s3 inet dhcp/enp0s3 inet static/" $network_config_file

# specify the static address as the address that had beein assigned by the dhcp
echo "\taddress $ipaddr/30" >> $network_config_file

# specify the gateway
echo "\tgateway $gateway" >> $network_config_file

################################################################################
### ssh config
################################################################################

echo "\n\nconfiguring SSH rules\n\n"

ssh_config_file=/etc/ssh/sshd_config

# change default ssh port to 50000
sed -i "s/#Port 22/Port 50000/" $ssh_config_file

# forbid ssh connections to the root account
sed -i "s/PermitRootLogin.*/PermitRootLogin no/" $ssh_config_file
sed -i "s/#StrictModes.*/StrictModes yes/" $ssh_config_file

# enable ssh authentication via public keys 
sed -i "s/#PubkeyAuthentication.*/PubkeyAuthentication yes/" $ssh_config_file

# disable all other modes of ssh authentication
sed -i "s/#PasswordAuthentication.*/PasswordAuthentication no/" $ssh_config_file
sed -i "s/#HostbasedAuthentication.*/HostbasedAuthentication no/" $ssh_config_file
sed -i "s/#ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/" $ssh_config_file
sed -i "s/#PermitEmptyPassword.*/PermitEmptyPassword no/" $ssh_config_file
sed -i "s/#UsePAM.*/UsePAM no/" $ssh_config_file
sed -i "s/UsePAM.*/UsePAM no/" $ssh_config_file

# create a folder for rsa keys at the standard emplacement and generate a keypair
mkdir -p ~/.ssh
ssh-keygen -q -f ~/.ssh/id_rsa -N ""

################################################################################
### network config
################################################################################

echo "\n\nconfiguring network rules\n\n"

# accept loopback
iptables -t mangle -A PREROUTING -i lo -j ACCEPT

# reject connection attemps from any IP that already has 10 open connections
iptables -t mangle -A PREROUTING -p tcp -m connlimit --connlimit-above 10 -j REJECT --reject-with tcp-reset

# accept new connections attempts to the ports 50000 (ssh), 80 (http), and 25 (smtp) from any IP that has attempted less than 20 connexions in the last 60 seconds
iptables -t mangle -A PREROUTING -p tcp --syn -m conntrack --ctstate NEW -m limit --limit 60/s --limit-burst 20 -m multiport --dports 50000,80,25 -j ACCEPT

# accept connections that are either already established or from related machines
iptables -t mangle -A PREROUTING -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# accept 1 ping per second
iptables -t mangle -A PREROUTING -p icmp -m icmp --icmp-type 8 -m limit --limit 1/second -j ACCEPT

# the rules defined for PREROUTING are repeated for INPUT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p tcp -m connlimit --connlimit-above 10 -j REJECT --reject-with tcp-reset
iptables -A INPUT -p tcp -m conntrack --ctstate NEW -m limit --limit 60/s --limit-burst 20 -m multiport --dports 50000,80,25 -j ACCEPT
iptables -A INPUT -p icmp -m icmp --icmp-type 8 -m limit --limit 1/second -j ACCEPT
iptables -A INPUT -p tcp -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# after having defined acceptable packets, set the standrd policies for all other packets to DROP
iptables -t mangle -P PREROUTING DROP
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# make ipv4 rules persistent and set ipv6 rules to drop
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
apt-get install -y iptables-persistent
sed -i "s/ACCEPT/DROP/" /etc/iptables/rules.v6


################################################################################
### set back sudoers
################################################################################

#mv /etc/sudoers_cpy /etc/sudoers
su sudouser
