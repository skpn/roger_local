
#!/bin/bash

################################################################################
### set custom variables
################################################################################

## get variables from setup_config file
if [ -f setup_config ]; then
	source setup_config
else
	echo "configuration file 'setup_config' was not found"
	while [ 1 ];
	do
		read -p "Please define a new user name: " $username
		read -p "Please retype the new user name: " $username_check
		if [ $username == $username_check ]; then
			break
		else
			echo "User name does not match."
		fi
	done
fi


################################################################################
### setting log file
################################################################################

log_file="/root/setup_log.txt"

echo -e "\n\nscript log file: $log_file\n\n"

exec &> >(tee -a $log_file) | exit 1

################################################################################
### packages update
################################################################################

echo -e "\n\nupdating packages\n\n"

###
echo -e "setting the source list to the debian mirror"
sed -i 's/^deb cdrom/# deb cdrom/g' /etc/apt/sources.list

###
echo -e "pre-setting options for package installation"
echo -e "iptables-persistent iptables-persistent/autosave_v4 boolean "
	"true" | debconf-set-selections
echo -e "iptables-persistent iptables-persistent/autosave_v6 boolean "
	"true" | debconf-set-selections

###
echo -e "updating sources, upgrading, installing necessary packages"
apt -y update
apt -y upgrade
apt -y autoremove
apt -y install sudo
apt -y install iptables-persistent
apt -y install git
apt -y install vim
apt -y install incron
apt -y install sendmail


################################################################################
### user config
################################################################################

echo -e "\n\ncreating independant sudo user\n\n"

###
echo -e "creating new sudo user '$username'"

adduser --ingroup sudo --disabled-password --gecos "" $username


################################################################################
### network config
################################################################################

echo -e "\n\nconfiguring static IP rules\n\n"

###
echo -e "getting current IP and gateway to re-use in static interface "
	"configuration"
ipaddr=$(ip addr show enp0s3 | awk '{ if ($1 == "inet") print $2}')
gateway=$(ip route show default | awk '{ print $3 }')
network_config_file=/etc/network/interfaces

###
echo -e "setting the enp0s3 interface to start at boot"
sed -i "s/iface enp0s3.*/auto enp0s3\\n&/" $network_config_file

###
echo -e "changing the enp0s3 interface type from dhcp to static"
sed -i "s/enp0s3 inet dhcp/enp0s3 inet static/" $network_config_file

###
echo -e "specifying the static address and gateway"
echo -e "\taddress $ipaddr/30" >> $network_config_file
echo -e "\tgateway $gateway" >> $network_config_file


################################################################################
### ssh config
################################################################################

echo -e "\n\nconfiguring SSH rules\n\n"

ssh_conf=/etc/ssh/sshd_config

###
echo -e "changing default ssh port to 50000"
sed -i "s/#Port 22/Port 50000/" $ssh_conf

###
echo -e "disabling ssh connections to the root account"
sed -i "s/#PermitRootLogin.*/PermitRootLogin no/" $ssh_conf

###
echo -e "allowing ssh authentication via public keys"
sed -i "s/#PubkeyAuthentication.*/PubkeyAuthentication yes/" $ssh_conf

###
echo -e "disabling all other modes of ssh authentication"
sed -i "s/#PasswordAuthentication.*/PasswordAuthentication no/" $ssh_conf
sed -i "s/#PermitEmptyPassword.*/PermitEmptyPassword no/" $ssh_conf
sed -i "s/#HostbasedAuthentication.*/HostbasedAuthentication no/" $ssh_conf

###
echo -e "creating a rsa keys at /$username/.ssh/id_rsa"

mkdir -p /$username/.ssh
ssh-keygen -y -q -f /$username/.ssh/id_rsa -N ""
exit 1

################################################################################
### network config
################################################################################

echo -e "\n\ncreating network rule files\n\n"

###
echo -e "flushing all previous ipv4 rules"
&éiptables -F
iptables -X

###
echo -e "flushing all previous ipv6 rules"
ip6tables -P INPUT ACCEPT
ip6tables -P FORWARD ACCEPT
ip6tables -P OUTPUT ACCEPT
ip6tables -t nat -F
ip6tables -t mangle -F
ip6tables -F
ip6tables -X

###
echo -e "rejecting connection attemps from any IP that already has 10 open "
	"connections"
iptables -t mangle -A PREROUTING -p tcp -m connlimit --connlimit-above 10	\
	-j DROP

###
echo -e "accepting new connections attempts to the ssh (50000), http (80), and "
	"smtp (25) ports from any IP that has attempted less than 20 connexions in "
	"the last 60 seconds"
iptables -t mangle -A PREROUTING -p tcp --syn -m conntrack --ctstate NEW	\
	-m limit --limit 60/s --limit-burst 20 -m multiport 					\
	--dports 50000,80,25 -j ACCEPT

###
echo -e "rejecting other new connections"
iptables -t mangle -A PREROUTING -p tcp --syn -m conntrack --ctstate NEW -j DROP

###
echo -e "accepting 1 ping per second"
iptables -t mangle -A PREROUTING -p icmp -m icmp --icmp-type 8 -m limit	\
	--limit 1/s -j ACCEPT

###
echo -e "rejecting other icmp packets"
iptables -t mangle -A PREROUTING -p icmp -j DROP

###
echo -e "adding ACCEPT rules defined for mangle to filter for final acceptance"
iptables -A INPUT -p tcp -m conntrack --ctstate NEW -m limit --limit 60/s 	\
	--limit-burst 20 -m multiport --dports 50000,80,25 -j ACCEPT
iptables -A INPUT -p icmp -m icmp --icmp-type 8 -m limit --limit 1/s -j ACCEPT

###
echo -e "accepting loopback packets"
iptables -A INPUT -i lo -j ACCEPT

###
echo -e "accepting established connections and connections from related machines"
iptables -A INPUT -p tcp -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

###
echo -e "setting the standard policies for all other packets to DROP"
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

###
echo -e "setting ipv6 policies to drop"
ip6tables -P INPUT DROP
ip6tables -P FORWARD DROP
ip6tables -P OUTPUT DROP

###
echo -e "making iptable configuration persistent"
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6


################################################################################
### disable unneeded services
################################################################################

echo -e "\n\ndisabling unneeded services\n\n"

# apparmor creates application profiles to limit resource access
echo -e "disabling apparmor (application resource access control)"
systemctl stop apparmor.service
systemctl disable apparmor.service
systemctl mask apparmor.service

# autovt@ manages virtual terminals for easier interaction between network hosts
# with different configurations
echo -e "disabling autovt@ (virtual terminals manager)"
systemctl stop autovt@.service
systemctl disable autovt@.service
systemctl mask autovt@.service

# console-setup specifies the encoding and font of the console,
# among other things
echo -e "disabling console-setup"
systemctl stop console-setup.service
systemctl disable console-setup.service
systemctl mask console-setup.service

# console-setup specifies keyboard configuration to activate the dead keys,
# among other things
echo -e "disabling keyboard-setup"
systemctl stop keyboard-setup.service
systemctl disable keyboard-setup.service
systemctl mask keyboard-setup.service


################################################################################
### sources update
################################################################################

update_sh="/root/update_script.sh"
update_cmd="bash $update_sh"
update_log="/var/log/update_script.log"

###
echo -ne "creating apt source update logging script "
echo -e "(script: $update_sh, log file: $update_log)"
echo -e 'apt -y update && apt -y upgrade' > update_sh

###
echo -e "setting system crontab to run update script at boot and 4AM"
sed -i 's/^#$//g' /etc/crontab
echo -e "0 4 * * *\troot\t$update_cmd" >> /etc/crontab
echo -e "@reboot\t\troot\t$update_cmd" >> /etc/crontab


################################################################################
### file surveillance script
################################################################################

echo -e "\n\nsetting alert on crontab modification\n\n"

###
file="/etc/crontab"

## dynamic timestamp for notification email
subject="subject: $HOSTNAME: $file was modified"

## changing and sourcing root's mail redirection
echo -e "setting new mail for root"
sed -i 's/root:/#root:/' /etc/aliases
newaliases

## setting incron
echo root >> /etc/incron.allow
echo "$file IN_MODIFY mail -s $subject root < /dev/null" >> /etc/incron.d/root


################################################################################
### exit script
################################################################################

###
echo "" >> $log_file

echo -e "\n\nVM set up, exiting - script log file: $log_file\n\n"
exit 1
