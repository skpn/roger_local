
################################################################################
### firewall config
################################################################################

echo -e "\n\nsetting up firewall rules\n\n"

sudo ufw enable

### set default policy
sudo ufw default deny incoming
sudo ufw default allow outgoing

### allow necessary ports: FTP (20, 21), SMTP(25), DNS (53), HTTP (80),
### HTTPS (443), custom SSH (50000)
sudo ufw allow 20/tcp
sudo ufw allow 21/tcp
sudo ufw allow 25
sudo ufw allow 53
sudo ufw allow 80/tcp
sudo ufw allow 443
sudo ufw allow 50000/tcp

sudo ufw reload

### create custom configuration file for fail2ban

sudo echo -e "
[sshd]
enabled = true
port    = 50000
logpath = %(sshd_log)s
backend = %(sshd_backend)s
maxretry = 3
bantime = 600

[http-get-dos]
enabled = true
port = http,https
filter = http-get-dos
logpath = /var/log/apache2/access.log
maxretry = 300
findtime = 300
bantime = 600
action = iptables[name=HTTP, port=http, protocol=tcp]
" > /etc/fail2ban/jail.local

echo -e "
[Definition]
failregex = ^<HOST> -.*\"(GET|POST).*
ignoreregex =
" > /etc/fail2ban/http-get-dos.conf

sudo service fail2ban restart
