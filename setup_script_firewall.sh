
################################################################################
### firewall config
################################################################################

echo -e "\n\nsetting up firewall rules\n\n"

###
echo -e "flushing all previous ipv4 rules"
iptables -F
iptables -X

###
echo -e "flushing all previous ipv6 rules"
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
