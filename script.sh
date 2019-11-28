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

################################################################################
### network config
################################################################################

ipaddr=$(ifconfig enp0s3 | awk '{ if ($1 == "inet" print $2}')
gateway=$(iproute | awk '{ if ($1=="default") print $3 }')
network_config_file=/etc/network/interfaces

sed -i "s/iface enp0s3.*/auto enp0s3\\n&/" $network_config_file
sed -i "s/enp0s3 inet dhcp/enp0s3 inet static/" $network_config_file
echo -e "\taddress $ipaddr/30" >> $network_config_file
echo -e "\tgateway $gateway" >> $network_config_file

################################################################################
### ssh config
################################################################################

ssh_config_file=/etc/ssh/sshd_config
username=$(whoami)
if [ ! $username=="root" ]; then
	username=$(echo /home/$username)
fi
filename=$username/.ssh/id_rsa

sed -i "s/#Port 22/Port 50000/" $ssh_config_file
sed -i "s/PermitRootLogin.*/PermitRootLogin no/" $ssh_config_file
sed -i "s/#PasswordAuthentication.*/PasswordAuthentication no/" $ssh_config_file
sed -i "s/#PermitEmptyPassword.*/PermitEmptyPassword no/" $ssh_config_file
sed -i "s/#PubkeyAuthentication.*/PubkeyAuthentication yes/" $ssh_config_file
mkdir -p $filename
ssh-keygen -q -f $filename -N ""
