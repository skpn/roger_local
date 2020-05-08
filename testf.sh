if [ -f ./setup_config -o -f $1 ]; then
	source setup_config
else
	echo -e "Configuration file 'setup_config' was not found.\nYou can provide"\
		"the path to a config file like so: ./setup_scrip path/to/file.\nThe "\
		"config file must contain the definitons of the 'username' (the new"\
		"sudo user), 'root_email' (the mail taht will receive root emails),"\
		" and 'host_key' (the ssh public key that will be used to connect to"\
		"the machine after the setup) variables"
	exit 1
fi
