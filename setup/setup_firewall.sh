
################################################################################
### firewall config
################################################################################

ssh_port=$1

echo -e "\n\nsetting up firewall rules\n\n"

sudo ufw enable

### disable IPv6
sed -i 's/IPV6=yes/IPV6=no/g' /etc/default/ufw

### set default policy
sudo ufw default deny incoming
sudo ufw default allow outgoing

### allow necessary ports: FTP (20, 21), SMTP(25), DNS (53), HTTP (80),
### HTTPS (443), custom SSH ($ssh_port)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow $ssh_port/tcp

sudo ufw limit 80/tcp
sudo ufw limit 443/tcp
sudo ufw limit $ssh_port/tcp

sudo ufw reload

### create custom configuration files for fail2ban

sudo echo -e "
[sshd]
backend = auto
enabled = true
port = $ssh_port
filter = sshd
logpath = /var/log/syslog
findtime = 300
bantime = 600
maxretry = 3

[portscan]
backend = auto
enabled = true
filter = portscan
logpath = /var/log/syslog
findtime = 300
bantime = 600
maxretry = 1

[http-get-dos]
backend = auto
enabled = true
port = http,https
filter = http-get-dos
logpath = /var/log/apache2/access.log
maxretry = 100
findtime = 300
bantime = 600
action = iptables[name=HTTP, port=http, protocol=tcp]
" > /etc/fail2ban/jail.local

echo -e "
[Definition]
failregex = UFW BLOCK.* SRC=<HOST>
ignoreregex =
" > /etc/fail2ban/portscan.conf

echo -e "
[Definition]
failregex = ^<HOST> -.*\"(GET|POST).*
ignoreregex =
" > /etc/fail2ban/http-get-dos.conf

sudo service fail2ban restart
