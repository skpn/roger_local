
################################################################################
### disable unneeded services
################################################################################

echo -e "\n\ndisabling unused services\n\n"

function disable_service() {
	systemctl stop $1@.service
	systemctl disable $1@.service
	systemctl mask $1@.service
}

# console-setup specifies the encoding and font of the console, among other
# things
# keyboard-setup specifies keyboard configuration to activate the dead keys,
# among other things
# bluetooth is a short distance wireless data transfer protocol, not used by a
# server

echo -e "disabling console-setup, keyboard-setup, and bluetooth"

disable_service autovt@
disable_service console-setup
disable_service keyboard-setup
disable_service bluetooth
