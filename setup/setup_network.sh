
################################################################################
### network config
################################################################################

echo -e "\n\nconfiguring static IP rules\n\n"

###
echo -e "getting current IP and gateway to re-use in static interface "\
	"configuration"

ip_addr=$(ip addr show enp0s3 | awk '{ if ($1 == "inet") print $2}')
ip_addr=${ip_addr%/*}
gateway=$(ip route show default | awk '{ print $3 }')
network_conf=/etc/network/interfaces

###
echo -e "setting the enp0s3 interface to start at boot"
sed -i "s/iface enp0s3.*/auto enp0s3\\n&/" $network_conf

###
echo -e "changing the enp0s3 interface type from dhcp to static"
sed -i "s/enp0s3 inet dhcp/enp0s3 inet static/" $network_conf

###
echo -e "setting static ip address $ip_addr and gateway $gateway"
echo -e "\taddress $ip_addr/30" >> $network_conf
echo -e "\tgateway $gateway" >> $network_conf

service networking restart
