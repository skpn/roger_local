
################################################################################
### sources update script
################################################################################

update_script="/root/update_script.sh"
update_log="/var/log/update_script.log"

###
echo -ne "creating apt source update logging script (script: $update_script, "\
	"log file: $update_log)"
echo -e "apt -y update > $update_log" > $update_script
echo -e "apt -y upgrade >> $update_log" >> $update_script

###
echo -e "setting system crontab to run update script at boot and 4AM"
echo -e "0 4 * * 6		root	bash $update_script" >> /etc/crontab
echo -e "@reboot		root	bash $update_script" >> /etc/crontab


################################################################################
### file surveillance script
################################################################################

echo -e "

setting alert on crontab modification

"

###
file="/etc/crontab"

## dynamic timestamp for notification email
subject="subject: $HOSTNAME: $file was modified"

## changing and sourcing root's mail redirection
echo -e "setting new mail for root"
sed -i 's/root:/#root:/' /etc/aliases
newaliases

## setting incron
echo -e "root" >> /etc/incron.allow
echo -e "$file IN_MODIFY mail -s \"$subject\" root < /dev/null" >> /etc/incron.d/root
