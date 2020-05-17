
#!/bin/bash

################################################################################
### set custom variables
################################################################################

## get variables from setup_config file
if [ "$#" -lt 1 ]; then
	setup_source=$(find . -type f -name "setup_config")
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

if [ -z $username ]; then
	echo -e "Config file '$setup_source' is missing 'username' variable"
	exit 1
elif [ -z "$host_key" ]; then
	echo -e "Config file '$setup_source' is missing 'host_key' variable"
	exit 1
fi


################################################################################
### setting log file
################################################################################

log_file="/root/setup/setup_log.txt"

echo -e "\n\nscript log file: $log_file\n\n"

exec &> $log_file

function launch_subscript() {
	subscript=$(find . -type f -name "$1")
	if [ "$#" -gt 1 ]; then
		subscript_args="${@:2}"
	fi
	bash $subscript $subscript_args
}

launch_subscript setup_packages.sh

launch_subscript setup_user.sh $username

launch_subscript setup_ssh.sh $setup_source

launch_subscript setup_network.sh

launch_subscript setup_firewall.sh

launch_subscript setup_services.sh

launch_subscript setup_cronjobs.sh

################################################################################
### exit setup
################################################################################

###
echo ""

echo -e "\n\nVM set up - script log file: $log_file\n\n"
exit 1

echo -ne "choose new password for sudouser: "

passwd $username
