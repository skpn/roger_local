
################################################################################
### user config
################################################################################

echo -e "\n\ncreating independant sudo user\n\n"

username=$1

###
echo -e "creating new sudo user '$username'"

adduser --ingroup sudo --disabled-password --gecos "" $username

echo -e "'$username' has no password, if the script is interrupted, use the "\
	"'passwd \"$username\"' command to create one"
