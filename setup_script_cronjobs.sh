
################################################################################
### sources update script
################################################################################

update_sh="/root/update_script.sh"
update_cmd="bash $update_sh"
update_log="/var/log/update_script.log"

###
echo -ne "creating apt source update logging script "
echo -e "(script: $update_sh, log file: $update_log)"
echo -e 'apt -y update && apt -y upgrade' > update_sh

###
echo -e "setting system crontab to run update script at boot and 4AM"
sed -i 's/^#$//g' /etc/crontab
echo -e "0 4 * * *\troot\t$update_cmd" >> /etc/crontab
echo -e "@reboot\t\troot\t$update_cmd" >> /etc/crontab


################################################################################
### file surveillance script
################################################################################

echo -e "\n\nsetting alert on crontab modification\n\n"

###
file="/etc/crontab"

## dynamic timestamp for notification email
subject="subject: $HOSTNAME: $file was modified"

## changing and sourcing root's mail redirection
echo -e "setting new mail for root"
sed -i 's/root:/#root:/' /etc/aliases
newaliases

## setting incron
echo root >> /etc/incron.allow
echo "$file IN_MODIFY mail -s $subject root < /dev/null" >> /etc/incron.d/root
