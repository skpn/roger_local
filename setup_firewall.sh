
################################################################################
### firewall config
################################################################################

echo -e "\n\nsetting up firewall rules\n\n"

### the rules at the start of the chain are consulted first, so they have higher
### priority
### inserting a rule puts it at the start of a chain, appending it at the end
### we start by appending rules that reject all traffic ; then we insert rules
### that accept the packets we want

### create specific log file for iptables
if [ -z "$(grep 'iptables_' /etc/rsyslog.conf)" ]; then
	echo ":msg,contains,\"iptables_\" /var/log/iptables.log" >> /etc/rsyslog.conf
	service rsyslog restart
fi

### flushing all previous ipv4 rules
sudo iptables -F
sudo iptables -X

sudo ip6tables -F
sudo ip6tables -X


### setting the ipv4 standard policies to ACCEPT so that rules can be flushed
### to access the server if it crashes
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT

sudo ip6tables -P INPUT ACCEPT
sudo ip6tables -P FORWARD DROP
sudo ip6tables -P OUTPUT ACCEPT

### the rules appear in priority order:
### - accept trusted inbound traffic ; 
### - accept all outbound traffic ;
### - accept 5 inbound and 5 outbound icmp packets per secound ;

### accept established/related inbound traffic to the the ssh, http[s], and smtp ports
#sudo iptables -I INPUT  -p tcp -m multiport --dports 50000,80,443,25 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A INPUT -p tcp -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

### accept outbound traffic
sudo iptables -A OUTPUT -j ACCEPT

### accept 5 outbound icmp ping packets per second up to 1000 packets
sudo iptables -A OUTPUT -p icmp -m icmp --icmp-type echo-request -m limit --limit 5/s --limit-burst 1000 -j ACCEPT
sudo iptables -A INPUT -p icmp -m icmp --icmp-type echo-reply -m limit --limit 5/s --limit-burst 1000 -j ACCEPT

### reject invalid packets
sudo iptables -t mangle -A PREROUTING -m conntrack --ctstate INVALID -j DROP
sudo iptables -t mangle -A PREROUTING -p tcp ! --syn -m conntrack --ctstate NEW -j DROP
sudo iptables -t mangle -A PREROUTING -p tcp -m connlimit --connlimit-above 50 -j DROP
sudo iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL ALL -j DROP
sudo iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL NONE -j DROP
sudo iptables -t mangle -A PREROUTING -f -j DROP

### accept loopback packets
sudo iptables -A INPUT -i lo -j ACCEPT

### accept 1 connection attempt to the ssh (50000), http[s] (80,[443]), and smtp (25)
### ports per second up to 120 attempts
sudo iptables -A INPUT -p tcp -m multiport --dports 50000,80,443,25 -m conntrack --ctstate NEW -m limit --limit 4/s --limit-burst 300 -j ACCEPT


### rejecting all remaining traffic after logging it
sudo iptables -A INPUT -m limit --limit 20/minute --limit-burst 60 -j LOG --log-level 4 --log-prefix=iptables_reject:
sudo iptables -A INPUT -j REJECT
sudo iptables -A FORWARD -j REJECT

sudo ip6tables -A INPUT -j REJECT
sudo ip6tables -A OUTPUT -j REJECT
sudo ip6tables -A FORWARD -j REJECT

### making iptable configuration persistent
sudo iptables-save > /etc/iptables/rules.v4
sudo ip6tables-save > /etc/iptables/rules.v6
