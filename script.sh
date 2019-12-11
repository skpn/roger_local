#!/bin/bash

################################################################################
### packages update
################################################################################

echo -e script log file: /root/script_log.txt

exec &> >(tee -a "/root/script_log.txt")

echo -e "\n\nupdating packages\n\n"

sed -i 's/^deb cdrom/# deb cdrom/g' /etc/apt/sources.list

apt-get -y update
apt-get -y upgrade
apt-get -y install sudo
apt-get -y install vim
echo -e iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo -e iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
apt-get install -y iptables-persistent

################################################################################
### user config
################################################################################

echo -e "\n\ncreating independant sudo user\n\n"

# creating user 'sudouser' in group sudo with no personnal info and no password
adduser --ingroup sudo --disabled-password --gecos "" sudouser

#giving a password to the user 'sudouser'
echo -e "sudouser:sudopwd" | chpasswd
#cp /etc/sudoers /etc/sudoers_cpy
#echo -e 'sudouser ALL=NOPASSWD:ALL' | EDITOR='tee -a' visudo

################################################################################
### network config
################################################################################

echo -e "\n\nconfiguring static IP rules\n\n"

ipaddr=$(ip addr show enp0s3 | awk '{ if ($1 == "inet") print $2}')
gateway=$(ip route show default | awk '{ print $3 }')
network_config_file=/etc/network/interfaces

# get the enp0s3 interface up automatically at boot
sed -i "s/iface enp0s3.*/auto enp0s3\\n&/" $network_config_file

# change the enp0s3 interface type from dhcp to static
sed -i "s/enp0s3 inet dhcp/enp0s3 inet static/" $network_config_file

# specify the static address as the address that had beein assigned by the dhcp
echo -e "\taddress $ipaddr/30" >> $network_config_file

# specify the gateway
echo -e "\tgateway $gateway" >> $network_config_file

################################################################################
### ssh config
################################################################################

echo -e "\n\nconfiguring SSH rules\n\n"

ssh_config_file=/etc/ssh/sshd_config

# change default ssh port to 50000
sed -i "s/#Port 22/Port 50000/" $ssh_config_file

# forbid ssh connections to the root account
sed -i "s/#PermitRootLogin.*/PermitRootLogin no/" $ssh_config_file
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
keys_file=$(awk -F: /#AuthorizedKeysFile/{print} $ssh_config_file | cut -d'	' -f 2)
ssh-keygen -q -f ~/.ssh/id_rsa -N ""

################################################################################
### network config
################################################################################

echo -e "\n\ncreating network rule files\n\n"

# flush all previous ipv4 rules
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -t nat -F
iptables -t mangle -F
iptables -F
iptables -X

ip6tables -P INPUT ACCEPT
ip6tables -P FORWARD ACCEPT
ip6tables -P OUTPUT ACCEPT
ip6tables -t nat -F
ip6tables -t mangle -F
ip6tables -F
ip6tables -X


echo  reject connection attemps from any IP that already has 10 open connections
iptables -t mangle -A PREROUTING -p tcp -m connlimit --connlimit-above 10 -j DROP

echo  "accept new connections attempts to the ssh (50000), http (80), and smtp (25) ports from any IP that has attempted less than 20 connexions in the last 60 seconds"
iptables -t mangle -A PREROUTING -p tcp --syn -m conntrack --ctstate NEW -m limit --limit 60/s --limit-burst 20 -m multiport --dports 50000,80,25 -j ACCEPT

echo  reject other new connections
iptables -t mangle -A PREROUTING -p tcp --syn -m conntrack --ctstate NEW -j DROP

echo  accept 1 ping per second
iptables -t mangle -A PREROUTING -p icmp -m icmp --icmp-type 8 -m limit --limit 1/s -j ACCEPT

echo  reject other icmp packets
iptables -t mangle -A PREROUTING -p icmp -j DROP

echo  "the ACCEPT rules defined for PREROUTING are added to the default (filter) table for final acceptance"
iptables -A INPUT -p tcp -m conntrack --ctstate NEW -m limit --limit 60/s --limit-burst 20 -m multiport --dports 50000,80,25 -j ACCEPT
iptables -A INPUT -p icmp -m icmp --icmp-type 8 -m limit --limit 1/s -j ACCEPT

echo  accept loopback packets
iptables -A INPUT -i lo -j ACCEPT

echo  accept established connections and connections from related machines
iptables -A INPUT -p tcp -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

echo  after having defined acceptable packets, set the standrd policies for all other packets to DROP
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

echo  set ipv6 policies to drop
ip6tables -P INPUT DROP
ip6tables -P FORWARD DROP
ip6tables -P OUTPUT DROP

echo  make rules persistent
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6

################################################################################
### set back sudoers
################################################################################

#mv /etc/sudoers_cpy /etc/sudoers
echo done, switching to sudouser
su sudouser

exit 1
