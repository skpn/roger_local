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
su sudouser

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
filename=~/.ssh/id_rsa

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
sudo mkdir -p $filename
sudo ssh-keygen -q -f $filename -N ""



################################################################################
### set back sudoers
################################################################################

mv /etc/sudoers_cpy /etc/sudoers
