
################################################################################
### firewall config
################################################################################

echo -e "\n\nsetting up firewall rules\n\n"

### the rules at the start of the chain are consulted first, so they have higher
### priority
### inserting a rule puts it at the start of a chain, appending it at the end
### we start by appending rules that DROP all traffic ; then we insert rules
### that ACCEPT the packets we want
### necessary ports: 21 (FTP), 25 (SMTP), 53 (DNS), 80 (HTTP), 443 (HTTPS),
### 50000 (custom SSH)

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

multiports="-m multiport --dports 21,25,53,80,443,50000"

### the rules appear in priority order:
### - ACCEPT trusted inbound traffic ; 
### - ACCEPT all outbound traffic ;
### ACCEPT established/related inbound traffic to the necessary ports
sudo iptables -A INPUT -p tcp $multiports -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A INPUT -p udp $multiports -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

### ACCEPT outbound traffic
sudo iptables -A OUTPUT -j ACCEPT

### ACCEPT 5 icmp packets per second from trusted sources up to 1000 packets
sudo iptables -A INPUT -p icmp -m conntrack --ctstate ESTABLISHED,RELATED -m limit --limit 5/s --limit-burst 1000 -j ACCEPT

### DROP invalid packets
sudo iptables -t mangle -A PREROUTING -m connlimit --connlimit-above 50 -j DROP
sudo iptables -t mangle -A PREROUTING -m conntrack --ctstate INVALID -j DROP
sudo iptables -t mangle -A PREROUTING -p tcp ! --syn -m conntrack --ctstate NEW -j DROP
sudo iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL NONE -j DROP
sudo iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL ALL -j DROP
sudo iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP 
sudo iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
sudo iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,FIN,PSH,URG -j DROP
sudo iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN FIN,SYN -j DROP
sudo iptables -t mangle -A PREROUTING -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
sudo iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,RST FIN,RST -j DROP
sudo iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP
sudo iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,ACK FIN -j DROP
sudo iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,URG URG -j DROP
sudo iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,FIN FIN -j DROP
sudo iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,PSH PSH -j DROP
sudo iptables -t mangle -A PREROUTING -f -j DROP

### ACCEPT loopback packets
loopback_addr=$(ip addr show lo | awk '{ if ($1 == "inet") print $2}')
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT ! -i lo -s $loopback_addr -j DROP

### ACCEPT 1 connection attempt to the ssh (50000), http[s] (80,[443]), and smtp (25)
### ports per second up to 120 attempts
sudo iptables -A INPUT -p tcp $multiports -m conntrack --ctstate NEW -m limit --limit 4/s --limit-burst 300 -j LOG --log-prefix=iptables_ACCEPT_new:
sudo iptables -A INPUT -p tcp $multiports -m conntrack --ctstate NEW -m limit --limit 4/s --limit-burst 300 -j ACCEPT
sudo iptables -A INPUT -p udp $multiports -m conntrack --ctstate NEW -m limit --limit 4/s --limit-burst 300 -j ACCEPT


### LOG then DROP all remaining traffic
sudo iptables -A INPUT -m limit --limit 20/minute --limit-burst 60 -j LOG --log-level 4 --log-prefix=iptables_DROP:
sudo iptables -A INPUT -j DROP
sudo iptables -A FORWARD -j DROP

sudo ip6tables -A INPUT -j DROP
sudo ip6tables -A OUTPUT -j DROP
sudo ip6tables -A FORWARD -j DROP

### making iptable configuration persistent
sudo iptables-save > /etc/iptables/rules.v4
sudo ip6tables-save > /etc/iptables/rules.v6
