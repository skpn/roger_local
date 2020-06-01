
################################################################################
### disable unneeded services
################################################################################

echo -e "\n\ndisabling unused services\n\n"

# console-setup specifies the encoding and font of the console, among other
# things
# keyboard-setup specifies keyboard configuration to activate the dead keys,
# among other things
# bluetooth is a short distance wireless data transfer protocol, not used by a
# server

echo -e "disabling console-setup, keyboard-setup, and bluetooth"

service apache-htcacheclean stop
service apache2 stop
service bluetooth stop
service console-setup stop
service hwclock.sh stop
service keyboard-setup stop
