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

adduser --ingroup $sudo --disabled-password --gecos "" sudouser
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

sed -i "s/iface enp0s3.*/auto enp0s3\\n&/" $network_config_file >> script_log.txt
sed -i "s/enp0s3 inet dhcp/enp0s3 inet static/" $network_config_file >> script_log.txt
echo "\taddress $ipaddr/30" >> $network_config_file
echo "\tgateway $gateway" >> $network_config_file

################################################################################
### ssh config
################################################################################

echo "\nconfiguring SSH rules, please wait\n"

ssh_config_file=/etc/ssh/sshd_config

sed -i "s/#Port 22/Port 50000/" $ssh_config_file >> script_log.txt
sed -i "s/PermitRootLogin.*/PermitRootLogin no/" $ssh_config_file >> script_log.txt
sed -i "s/#StrictModes.*/StrictModes yes/" $ssh_config_file >> script_log.txt
sed -i "s/#PasswordAuthentication.*/PasswordAuthentication no/" $ssh_config_file >> script_log.txt
sed -i "s/#HostbasedAuthentication.*/HostbasedAuthentication no/" $ssh_config_file >> script_log.txt
sed -i "s/#ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/" $ssh_config_file >> script_log.txt
sed -i "s/#PermitEmptyPassword.*/PermitEmptyPassword no/" $ssh_config_file >> script_log.txt
sed -i "s/#PubkeyAuthentication.*/PubkeyAuthentication yes/" $ssh_config_file >> script_log.txt
sed -i "s/#UsePAM.*/UsePAM no/" $ssh_config_file >> script_log.txt
sed -i "s/UsePAM.*/UsePAM no/" $ssh_config_file >> script_log.txt
mkdir -p ~/.ssh >> script_log.txt
ssh-keygen -q -f ~/.ssh/id_rsa -N "" >> script_log.txt

################################################################################
### firewall config
################################################################################

echo "\nconfiguring firewall rules, please wait\n"

iptables -A INPUT -i lo -j ACCEPT >> script_log.txt
iptables -A INPUT -p tcp -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT >> script_log.txt
iptables -A INPUT -p tcp --syn -m conntrack --ctstate NEW -m multiport --dports 50000,80,25 -j ACCEPT >> script_log.txt
iptables -P INPUT DROP >> script_log.txt
iptables -P FORWARD DROP >> script_log.txt
iptables -P OUTPUT ACCEPT >> script_log.txt

################################################################################
### anti-DoS config
################################################################################

echo "\nconfiguring anti-DoS rules, please wait\n"

iptables -t mangle -A PREROUTING -i lo -j ACCEPT >> script_log.txt
iptables -t mangle -A PREROUTING -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT >> script_log.txt
iptables -t mangle -A PREROUTING -p tcp --syn -m conntrack --ctstate NEW -m multiport --dports 50000,80,25 -j ACCEPT >> script_log.txt
iptables -t mangle -P PREROUTING DROP >> script_log.txt
iptables -A INPUT -p tcp -m connlimit --connlimit-above 10 -j REJECT --reject-with tcp-reset >> script_log.txt
iptables -A INPUT -p tcp -m conntrack --ctstate NEW -m limit 60/s --limit-burst 20 -j ACCEPT >> script_log.txt
iptables -A INPUT -p tcp -m conntrack --ctstate NEW -j DROP >> script_log.txt

#check that ssh connection is still ok with this kind of stuff

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
