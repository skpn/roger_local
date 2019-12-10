#!/bin/bash

################################################################################
### packages config
################################################################################

echo "\nupdating packages, please wait\n"

sed -i 's/^deb cdrom/# deb cdrom/g' /etc/apt/sources.list >> script_log.txt

apt-get -y update >> script_log.txt
apt-get -y upgrade >> script_log.txt
apt-get -y install sudo >> script_log.txt
apt-get -y install vim >> script_log.txt

################################################################################
### user config
################################################################################

echo "\ncreating independant sudo user, please wait\n"

# creating user 'sudouser' in group sudo with no personnal info and no password
adduser --ingroup sudo --disabled-password --gecos "" sudouser

#giving a password to the user 'sudouser'
echo "sudouser:sudopwd" | chpasswd
#cp /etc/sudoers /etc/sudoers_cpy
#echo 'sudouser ALL=NOPASSWD:ALL' | EDITOR='tee -a' visudo

################################################################################
### network config
################################################################################

echo "\nconfiguring static IP rules, please wait\n"

ipaddr=$(ip addr show enp0s3 | awk '{ if ($1 == "inet") print $2}')
gateway=$(ip route show default | awk '{ print $3 }')
network_config_file=/etc/network/interfaces

# get the enp0s3 interface up automatically at boot
sed -i "s/iface enp0s3.*/auto enp0s3\\n&/" $network_config_file >> script_log.txt

# change the enp0s3 interface type from dhcp to static
sed -i "s/enp0s3 inet dhcp/enp0s3 inet static/" $network_config_file >> script_log.txt

# specify the static address as the address that had beein assigned by the dhcp
echo "\taddress $ipaddr/30" >> $network_config_file

# specify the gateway
echo "\tgateway $gateway" >> $network_config_file

################################################################################
### ssh config
################################################################################

echo "\nconfiguring SSH rules, please wait\n"

ssh_config_file=/etc/ssh/sshd_config

# change default ssh port to 50000
sed -i "s/#Port 22/Port 50000/" $ssh_config_file >> script_log.txt

# forbid ssh connections to the root account
sed -i "s/PermitRootLogin.*/PermitRootLogin no/" $ssh_config_file >> script_log.txt
sed -i "s/#StrictModes.*/StrictModes yes/" $ssh_config_file >> script_log.txt

# enable ssh authentication via public keys 
sed -i "s/#PubkeyAuthentication.*/PubkeyAuthentication yes/" $ssh_config_file >> script_log.txt

# disable all other modes of ssh authentication
sed -i "s/#PasswordAuthentication.*/PasswordAuthentication no/" $ssh_config_file >> script_log.txt
sed -i "s/#HostbasedAuthentication.*/HostbasedAuthentication no/" $ssh_config_file >> script_log.txt
sed -i "s/#ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/" $ssh_config_file >> script_log.txt
sed -i "s/#PermitEmptyPassword.*/PermitEmptyPassword no/" $ssh_config_file >> script_log.txt
sed -i "s/#UsePAM.*/UsePAM no/" $ssh_config_file >> script_log.txt
sed -i "s/UsePAM.*/UsePAM no/" $ssh_config_file >> script_log.txt

# create a folder for rsa keys at the standard emplacement and generate a keypair
mkdir -p ~/.ssh >> script_log.txt
ssh-keygen -q -f ~/.ssh/id_rsa -N "" >> script_log.txt

################################################################################
### network config
################################################################################

echo "\nconfiguring network rules, please wait\n"

# accept loopback
iptables -t mangle -A PREROUTING -i lo -j ACCEPT >> script_log.txt

# reject connection attemps from any IP that already has 10 open connections
iptables -t mangle -A PREROUTING -p tcp -m connlimit --connlimit-above 10 -j REJECT --reject-with tcp-reset >> script_log.txt

# accept new connections attempts to the ports 50000 (ssh), 80 (http), and 25 (smtp) from any IP that has attempted less than 20 connexions in the last 60 seconds
iptables -t mangle -A PREROUTING -p tcp --syn -m conntrack --ctstate NEW -m limit --limit 60/s --limit-burst 20 -m multiport --dports 50000,80,25 -j ACCEPT >> script_log.txt

# accept connections that are either already established or from related machines
iptables -t mangle -A PREROUTING -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT >> script_log.txt

# accept 1 ping per second
iptables -t mangle -A PREROUTING -p icmp -m icmp --icmp-type 8 -m limit --limit 1/second -j ACCEPT

# the rules defined for PREROUTING are repeated for INPUT
iptables -A INPUT -i lo -j ACCEPT >> script_log.txt
iptables -A INPUT -p tcp -m connlimit --connlimit-above 10 -j REJECT --reject-with tcp-reset >> script_log.txt
iptables -A INPUT -p tcp -m conntrack --ctstate NEW -m limit --limit 60/s --limit-burst 20 -m multiport --dports 50000,80,25 -j ACCEPT >> script_log.txt
iptables -A INPUT -p icmp -m icmp --icmp-type 8 -m limit --limit 1/second -j ACCEPT
iptables -A INPUT -p tcp -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT >> script_log.txt

# after having defined acceptable packets, set the standrd policies for all other packets to DROP
iptables -t mangle -P PREROUTING DROP >> script_log.txt
iptables -P INPUT DROP >> script_log.txt
iptables -P FORWARD DROP >> script_log.txt
iptables -P OUTPUT ACCEPT >> script_log.txt

# make ipv4 rules persistent and set ipv6 rules to drop
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
apt-get install -y iptables-persistent >> script_log.txt
sed -i "s/ACCEPT/DROP/" /etc/iptables/rules.v6 >> script_log.txt


################################################################################
### set back sudoers
################################################################################

#mv /etc/sudoers_cpy /etc/sudoers
echo script log file: /root/script_log.txt
su sudouser >> script_log.txt
