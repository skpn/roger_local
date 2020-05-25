
################################################################################
### firewall config
################################################################################

echo -e "\n\nsetting up firewall rules\n\n"

sudo ufw enable

### allow necessary ports: FTP, SMTP, DNS, HTTP, HTTPS, custom SSH
sudo ufw allow 21
sudo ufw allow 25
sudo ufw allow 53
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 50000

sudo ufw reload

### create custom configuration file for fail2ban

sudo echo -e "
[sshd]
enabled = true
port    = 42
logpath = %(sshd_log)s
backend = %(sshd_backend)s
maxretry = 3
bantime = 600

[http-get-dos]
enabled = true
port = http,https
filter = http-get-dos
logpath = /var/log/apache2/access.log (le fichier d'access sur server web)
maxretry = 300
findtime = 300
bantime = 600
action = iptables[name=HTTP, port=http, protocol=tcp]
" > /etc/fail2ban/jail.local

sudo service fail2ban restart

### edit portsentry configuration files

sudo sed -i 's/TCP_MODE="tcp"/TCP_MODE="atcp"/g' /etc/default/portsentry
sudo sed -i 's/UDP_MODE="udp"/UDP_MODE="audp"/g' /etc/default/portsentry

sudo sed -i 's/BLOCK_TCP="0"/BLOCK_TCP="1"/g' /etc/portsentry/portsentry.conf
sudo sed -i 's/BLOCK_UDP="0"/BLOCK_UDP="1"/g' /etc/portsentry/portsentry.conf

sudo sed -i 's/^KILL/^#KILL/g' /etc/portsentry/portsentry.conf
sudo sed -i 's/#KILL_ROUTE="/sbin/iptables -I INPUT -s $TARGET$ -j DROP"/KILL_ROUTE="/sbin/iptables -I INPUT -s $TARGET$ -j DROP"/g' /etc/portsentry/portsentry.conf

sudo service portsentry restart