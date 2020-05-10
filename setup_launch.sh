
#!/bin/bash

################################################################################
### set custom variables
################################################################################

## get variables from setup_config file
if [ "$#" -lt 1 ]; then
	setup_source="setup_config"
elif [ "$#" -eq 1 ]; then
	setup_source=$1
	echo -e "Using file $1 as config file"
else
	echo -e "Usage: bash setup_script.sh [path/to/config/file]"
	exit 1
fi

if [ -f $setup_source ]; then
	source $setup_source
else
	echo -e "Configuration file '$setup_source' was not found.\nYou can provide"\
		"the path to a config file like so: ./setup_scrip path/to/file.\nThe "\
		"config file must contain the definitons of the 'username' (the new"\
		"sudo user) and 'host_key' (the ssh public key that will be used to "\
		"connect to the machine after the setup) variables"
	exit 1
fi

if [ -z $username ] || [ z $host_key ]; then
	echo -e "Config file '$setup_source' is missing 'username' and/or "\
		"'host_key' variable(s)"
	exit 1
fi


################################################################################
### setting log file
################################################################################

log_file="/root/setup_log.txt"

echo -e "\n\nscript log file: $log_file\n\n"

exec &> $log_file

bash setup_packages.sh

bash setup_user.sh $username

bash setup_ssh.sh $username $host_key

bash setup_network.sh

bash setup_firewall.sh

bash setup_services.sh

bash setup_cronjobs.sh

################################################################################
### exit setup
################################################################################

###
echo "" >> $log_file

echo -e "\n\nVM set up, exiting - script log file: $log_file\n\n"
exit 1
