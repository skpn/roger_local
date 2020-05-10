
repo="https://raw.githubusercontent.com/skpn/roger_local/master/"

function get_file() {
	rm $1
	wget_url=$repo$1
	wget $wget_url
}

echo "getting setup scripts and sub-scripts in setup folder"

mkdir setup

cd setup

get_file setup_script.sh
get_file setup_script_cronjobs.sh
get_file setup_script_firewall.sh
get_file setup_script_network.sh
get_file setup_script_packages.sh
get_file setup_script_services.sh
get_file setup_script_ssh.sh
get_file setup_script_user.sh
get_file setup_config

cd ..
