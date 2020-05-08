
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
