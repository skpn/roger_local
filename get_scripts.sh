
repo="https://raw.githubusercontent.com/skpn/roger_local/master/"

function get_file() {
	rm -f $(find . -type f -name "$1")
	wget_url=$repo$1
	wget -q -O setup/$1 $wget_url
	if [ ! -f setup/$1 ]; then
		echo -e "could not get file $1"
		exit 1
	else
		echo -e "got file '$1' in 'setup' folder"
	fi
}

echo "getting setup scripts and sub-scripts in setup folder"

mkdir -p setup

get_file setup_launch.sh
get_file setup_cronjobs.sh
get_file setup_firewall.sh
get_file setup_network.sh
get_file setup_packages.sh
get_file setup_services.sh
get_file setup_ssh.sh
get_file setup_user.sh
get_file setup_config
