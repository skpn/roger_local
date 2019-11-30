#!/bin/bash

exit 1

#need to partition
#need to dl script

################################################################################
### packages config
################################################################################

sed -i 's/^deb cdrom/# deb cdrom/g' /etc/apt/sources.list

apt-get -y update
apt-get -y upgrade
apt-get -y install sudo
apt-get -y install vim

################################################################################
### sudo user config
################################################################################

sudo_gid=$(getent group sudo | cut -d ':' -f 3)

adduser --gid $sudo_gid --disabled-password --gecos "" sudouser
echo "sudouser:sudopwd" | chpasswd
cp /etc/sudoers /etc/sudoers_cpy
echo 'sudouser ALL=NOPASSWD:ALL' | sudo EDITOR='tee -a' visudo

################################################################################
### network config
################################################################################

ipaddr=$(ip addr show enp0s3 | awk '{ if ($1 == "inet") print $2}')
gateway=$(ip route show default | awk '{ print $3 }')
network_config_file=/etc/network/interfaces

sudo sed -i "s/iface enp0s3.*/auto enp0s3\\n&/" $network_config_file
sudo sed -i "s/enp0s3 inet dhcp/enp0s3 inet static/" $network_config_file
sudo echo "\taddress $ipaddr/30" >> $network_config_file
sudo echo "\tgateway $gateway" >> $network_config_file

################################################################################
### ssh config
################################################################################

ssh_config_file=/etc/ssh/sshd_config

sudo sed -i "s/#Port 22/Port 50000/" $ssh_config_file
sudo sed -i "s/PermitRootLogin.*/PermitRootLogin no/" $ssh_config_file
sudo sed -i "s/#StrictModes.*/StrictModes yes/" $ssh_config_file
sudo sed -i "s/#PasswordAuthentication.*/PasswordAuthentication no/" $ssh_config_file
sudo sed -i "s/#HostbasedAuthentication.*/HostbasedAuthentication no/" $ssh_config_file
sudo sed -i "s/#ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/" $ssh_config_file
sudo sed -i "s/#PermitEmptyPassword.*/PermitEmptyPassword no/" $ssh_config_file
sudo sed -i "s/#PubkeyAuthentication.*/PubkeyAuthentication yes/" $ssh_config_file
sudo sed -i "s/#UsePAM.*/UsePAM no/" $ssh_config_file
sudo sed -i "s/UsePAM.*/UsePAM no/" $ssh_config_file
sudo mkdir -p ~/.ssh
sudo ssh-keygen -q -f ~/.ssh/id_rsa -N ""

################################################################################
### firewall config
################################################################################

sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A INPUT -p tcp -dport 50000 -j ACCEPT
sudo iptables -A INPUT -p tcp -dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp -dport 25 -j ACCEPT
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
apt-get install -y iptables-persistent
sudo sed -i "s/ACCEPT/DROP/" /etc/iptables/rules.v6


################################################################################
### set back sudoers
################################################################################

mv /etc/sudoers_cpy /etc/sudoers
su sudouser
