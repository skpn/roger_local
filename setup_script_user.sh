
################################################################################
### user config
################################################################################

echo -e "\n\ncreating independant sudo user\n\n"

###
echo -e "creating new sudo user '$1'"

adduser --ingroup sudo --disabled-password --gecos "" $1

