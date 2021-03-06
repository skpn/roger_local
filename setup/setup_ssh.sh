
################################################################################
### ssh config
################################################################################

echo -e "\n\nconfiguring SSH rules\n\n"

ssh_conf="/etc/ssh/sshd_config"

source $1

###
echo -e "changing default ssh port to $ssh_port"
sed -i "s/#Port 22/Port $ssh_port/" $ssh_conf

###
echo -e "allowing ssh authentication via public keys"
sed -i "s/#PubkeyAuthentication.*/PubkeyAuthentication yes/" $ssh_conf

###
echo -e "storing trusted keys in /home/$username/.ssh/authorized_keys"
mkdir -p /home/$username/.ssh
echo $host_key > /home/$username/.ssh/authorized_keys

###
echo -e "disabling all other modes of ssh authentication"
sed -i "s/#PasswordAuthentication.*/PasswordAuthentication no/" $ssh_conf
sed -i "s/#HostbasedAuthentication.*/HostbasedAuthentication no/" $ssh_conf

###
echo -e "disabling ssh connections to the root account"
sed -i "s/#PermitRootLogin.*/PermitRootLogin no/" $ssh_conf

service ssh restart
