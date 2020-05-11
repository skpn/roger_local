
################################################################################
### firewall config
################################################################################

echo -e "\n\nsetting up firewall rules\n\n"

### flushing all previous ipv4 rules
iptables -F
iptables -X

ip6tables -F
ip6tables -X

### accepting loopback packets
iptables -A INPUT -i lo -j ACCEPT

### accepting established connections and connections from related machines
iptables -t nat -A PREROUTING -p tcp -m conntrack \
	--ctstate ESTABLISHED,RELATED -j ACCEPT

### accepting output traffic from the ssh, http, and smtp ports
iptables -I OUTPUT -p tcp -m multiport --dports 50000,80,25 -j ACCEPT

### accepting 1 connection attempt to the ssh (50000), http (80), and smtp (25)
### ports per second up to 120 attempts per ip address
iptables -t nat -I PREROUTING -p tcp --syn -m conntrack --ctstate NEW	\
	-m limit --limit 10/minute --limit-burst 120 \
	-m multiport --dports 50000,80,25 -j ACCEPT

### accepting ping 5 icmp protocol pings per second up to 1000 pings
iptables -I INPUT -p icmp -m icmp --icmp-type 8 -m limit --limit 5/s \
	--limit-burst 1000 -j ACCEPT


#useless if policy is drop
### rejecting other new connections
#iptables -t nat -A PREROUTING -p tcp --syn -m conntrack --ctstate NEW -j REJECT

#useless if policy is drop
### rejecting any connection attemps from any IP that already has 10 open
### connections
#iptables -t nat -I PREROUTING -p tcp -m connlimit --connlimit-above 5 -j REJECT

#useless if policy is drop
### rejecting other icmp packets
#iptables -A PREROUTING -p icmp -j DROP


### setting the standard policies to DROP
iptables -P INPUT REJECT
iptables -P FORWARD REJECT
iptables -P OUTPUT REJECT

ip6tables -P INPUT REJECT
ip6tables -P FORWARD REJECT
ip6tables -P OUTPUT REJECT

### making iptable configuration persistent
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6
