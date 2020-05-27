
################################################################################
### packages update
################################################################################

echo -e "\n\nupdating packages\n\n"

###
echo -e "setting the source list to the debian mirror"
sed -i 's/^deb cdrom/# deb cdrom/g' /etc/apt/sources.list

###
###
echo -e "updating sources, upgrading, installing necessary packages"

apt -y -qq update
apt -y -qq upgrade
apt -y -qq autoremove

apt -y -qq install sudo
apt -y -qq install git
apt -y -qq install vim
apt -y -qq install ufw
apt -y -qq install fail2ban
apt -y -qq install ssh
apt -y -qq install incron
apt -y -qq install mailutils
