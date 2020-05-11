
################################################################################
### firewall config
################################################################################

echo -e "\n\nsetting up firewall rules\n\n"

### we start by appending rules that reject all traffic ; then we insert rules
### that accept the packets we want

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


### rejecting all traffic
sudo iptables -A INPUT -j LOG --log-prefix=iptables:
sudo iptables -A INPUT -j REJECT
sudo iptables -A OUTPUT -j LOG --log-prefix=iptables:
sudo iptables -A OUTPUT -j REJECT
sudo iptables -A FORWARD -j REJECT

sudo ip6tables -A INPUT -j REJECT
sudo ip6tables -A OUTPUT -j REJECT
sudo ip6tables -A FORWARD -j REJECT


### accepting output traffic from the ssh, http, and smtp ports
sudo iptables -I OUTPUT -p tcp -m multiport --dports 50000,80,25 -j ACCEPT

### accepting 5 icmp protocol inbound pings per second up to 1000 pings
sudo iptables -I INPUT -p icmp -m icmp --icmp-type 8 -m limit --limit 5/s --limit-burst 1000 -j ACCEPT

### accepting icmp protocol outbound pings
sudo iptables -I OUTPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT

### accepting 1 connection attempt to the ssh (50000), http (80), and smtp (25)
### ports per second up to 120 attempts per ip address
sudo iptables -I PREROUTING  -p tcp --syn -m conntrack --ctstate NEW -m limit --limit 10/minute --limit-burst 120 -m multiport --dports 50000,80,25 -j ACCEPT

### accepting loopback packets
sudo iptables -I INPUT -i lo -j ACCEPT

### accepting established connections and connections from related machines
sudo iptables -I PREROUTING -p tcp -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

### making iptable configuration persistent
sudo iptables-save > /etc/sudo iptables/rules.v4
sudo ip6tables-save > /etc/sudo iptables/rules.v6
