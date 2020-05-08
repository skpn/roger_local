
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
echo -e "creating rsa keys in /$username/.ssh"

mkdir -p /$username/.ssh
echo $host_key > /$username/.ssh/authorized_keys

service ssh restart
