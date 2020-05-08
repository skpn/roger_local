
################################################################################
### disable unneeded services
################################################################################

echo -e "\n\ndisabling unused services\n\n"

# apparmor creates application profiles to limit resource access
echo -e "disabling apparmor (application resource access control)"
systemctl stop apparmor.service
systemctl disable apparmor.service
systemctl mask apparmor.service

# autovt@ manages virtual terminals for easier interaction between network hosts
# with different configurations
echo -e "disabling autovt@ (virtual terminals manager)"
systemctl stop autovt@.service
systemctl disable autovt@.service
systemctl mask autovt@.service

# console-setup specifies the encoding and font of the console,
# among other things
echo -e "disabling console-setup"
systemctl stop console-setup.service
systemctl disable console-setup.service
systemctl mask console-setup.service

# console-setup specifies keyboard configuration to activate the dead keys,
# among other things
echo -e "disabling keyboard-setup"
systemctl stop keyboard-setup.service
systemctl disable keyboard-setup.service
systemctl mask keyboard-setup.service
