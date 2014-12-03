#===========================================================================
#
#          File:  setup-gpg.sh
# 
#   Description:  Setup script to have a best practice gpg setting.
#                 Still not working correctly!
# 
#       Options:  ---
#  Requirements:  bash shell
#          Bugs:  Still not working correctly!
#         Notes:  This script is based on input from:
#
#   http://www.gnupg.org/documentation/manuals/gnupg-devel/Unattended-GPG-key-generation.html#Unattended-GPG-key-generation
#   https://github.com/attila-lendvai/gpg-keygen/blob/master/gpg-keygen.py
#   https://stackoverflow.com/questions/7522712/how-to-check-if-command-exists-in-a-shell-script/7522744#7522744
#   https://wiki.archlinux.org/index.php/GnuPG#Rotating_subkeys
#   https://wiki.debian.org/subkeys
#   http://keyring.debian.org/creating-key.html
#   http://www.spywarewarrior.com/uiuc/gpg/gpg-com-4.htm#toc
#   
#
#          Todo: - create menue for paranoid scale
#                - remove master secret key (not working yet)
#                - create aliases in bashrc for easy key management from usb
#                  disk
#                 
#       Version:  0.3
#       Created:  11/22/13 13:19:06 UTC
#      Revision:  Sun Jan 26 15:19:43 2014
# 
#         Usage:  ./setup-gpg.sh
# 
#        Output:  ---
#
#        Author:  Frank Milde (FM), frank.milde (at) posteo.de
#       Company:  ---
#
#===========================================================================

#!/bin/bash

#---------------------------------------------------------------------------
#   globals
#---------------------------------------------------------------------------
NAME="Testy Test"
EMAIL="test@test.de"

DIR=.gnupg
CONF_FILE=gpg.conf
AGENT_FILE=gpg-agent.conf
THUNDERBIRD_FILE=use-thunderbird-with-gpg-agent.sh

#---------------------------------------------------------------------------
#   functions
#---------------------------------------------------------------------------
function greeting () {
  clear
  echo 
  echo "$(tput setaf 3) --- Setting up a gpg encryption environment ---\
    $(tput sgr0)"
  echo 
  sleep 1
  read -p "Press Enter to continue, or abort by pressing Ctrl-c" nothing
}    # ----------  end of function greeting  ----------

function is_gpg_installed () {
if ! type -P gpg 1>/dev/null;
  then
    local choice
    read -e -p "Gnupg is not installed. Install y/n? (y)" choice
    choice=${choice:-y}
    if [[ ${choice} == y ]]
    then
      install_gpg
    else
      exit 0
    fi
  fi
}    # ----------  end of function is_gpg_installed  ----------

function install_gpg () {
	local find_apt=$(which apt 2>&1)
	local find_pacman=$(which pacman 2>&1)

	if [[ ${find_apt} =~ ^"no apt" ]]
	then
		echo "sudo apt-get install gnupg"
	else 
		if [[ ${find_pacman} =~ ^"no pacman" ]]
		then
			echo "sudo pacman -S install gnupg"
		else 
			echo "Please install gnupg."
		fi
	fi
}  # -----  end of function install_gpg  -----

#===  FUNCTION  ============================================================
#          Name:  user_input
#   Description:  Gets full name and email address from user 
#       Globals:  NAME
#                 EMAIL
#     Arguments:  None.
#       Returns:  None.
#===========================================================================
function user_input () {
  read -e -p "Enter your full name    : " NAME
  read -e -p "Enter your email-address: " EMAIL
}    # ----------  end of function user_input  ----------

#===  FUNCTION  ============================================================
#          Name:  create_conf_files
#   Description:  
#       Globals:  CONF_FILE
#                 AGENT_FILE
#                 THUNDERBIRD_STARTUP_SCRIPT
#
#     Arguments:  None.
#       Returns:  None.
#===========================================================================
function create_conf_files () {
echo "Creating conf files."

touch ${CONF_FILE}
tee ${CONF_FILE} << EOF >> /dev/null
fixed-list-mode
keyid-format 0xlong
personal-digest-preferences SHA512 SHA384 SHA256 SHA224
default-preference-list SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES \
CAST5 BZIP2 ZLIB ZIP Uncompressed
verify-options show-uid-validity
list-options show-uid-validity
sig-notation issuer-fpr@notations.openpgp.fifthhorseman.net=%g
cert-digest-algo SHA256
use-agent
lock-never
no-permission-warning
keyserver hkps.pool.sks-keyservers.net
keyserver-options ca-cert-file=/path/to/CA/sks-keyservers.netCA.pem
keyserver-options no-honor-keyserver-url
EOF

local username=$(whoami)

touch ${AGENT_FILE}
tee ${AGENT_FILE} << EOF >> /dev/null
default-cache-ttl 28800
max-cache-ttl 999999
ignore-cache-for-signing
enable-ssh-support
# Environment file
write-env-file /home/${username}/.gnupg/gpg-agent.env
EOF

touch ${THUNDERBIRD_FILE}
tee ${THUNDERBIRD_FILE} << 'EOF' >> /dev/null
#!/bin/sh

envfile="${HOME}/.gnupg/gpg-agent.env"
k
if test -f "$envfile" && \
  kill -0 $(grep GPG_AGENT_INFO "$envfile" | cut -d: -f 2) 2>/dev/null; then
  eval "$(cat "$envfile")"
else
  eval "$(gpg-agent --daemon --write-env-file "$envfile")"
fi

export GPG_AGENT_INFO  # the env file does not contain the export statement
export SSH_AUTH_SOCK
export SSH_AGENT_PID

/usr/bin/thunderbird
EOF
}    # ----------  end of function create_conf_files  ----------

#===  FUNCTION  ============================================================
#          Name:  create_master_key
#   Description:  
#       Globals:  EMAIL
#                 NAME
#     Arguments:  None.
#       Returns:  None.
#===========================================================================
function create_master_key() {
  echo "Generating master key. Fear not, this might take a while."
  cat >parameterfile <<EOF
    Key-Type: RSA
    Key-Length: 1024
    Key-Usage: sign
    Expire-Date: 5y
    Name-Real: ${NAME}
    Name-Email: ${EMAIL}
    %ask-passphrase
EOF
  gpg --batch --gen-key parameterfile
  shred -u parameterfile
}    # ----------  end of function create_master_key  ----------

#===  FUNCTION  ============================================================
#          Name:  get_master_key_fingerprint
#   Description:  
#       Globals:  EMAIL
#     Arguments:  None.
#       Returns:  fingerprint
#===========================================================================
function get_master_key_fingerprint () {
  local fingerprint=$(gpg --fingerprint ${EMAIL} | \
    awk '/fingerprint/ {for (i=4; i<NF; i++) printf $i " "; print $NF}')
  echo ${fingerprint}
}    # ----------  end of function get_master_key_fingerprint  ----------

#===  FUNCTION  ============================================================
#          Name:  create_master_key_revocation_certificate
#   Description:  
#       Globals:  EMAIL
#                 DIR
#     Arguments:  None.
#       Returns:  None.
#===========================================================================
function create_master_key_revocation_certificate () {
  local truncated_fingerprint=$(get_master_key_fingerprint | \
    awk '{for (i=7; i<NF; i++) printf $i ""; print $NF}')
local filename_base="revocation-certificate-for-${EMAIL}-\
${truncated_fingerprint}"
local filename_cleartext="$filename_base-cleartext.asc"
local filename_pwd="$filename_base-password-protected.asc"

  #TODO: Change order: keep cleartext in save place, leave encrypted in .gpg
  #      folder

  cat >README <<EOF

Generating the master revocation certificate. 

$(tput bold)ATTENTION$(tput sgr0):
(1) You will be asked to enter your master key passphrase (the one you set 
    moments ago). 

(2) You will be asked to set a second passphrase to (symmetrically) 
    encrypt your revocation certificate. 

    Store that encrypted revocation certificate in a save place (CD-ROM, USB
    thumb drive), where others have no easy access. If/when the certificate
    is needed in the future, you can decrypt it using
    $(tput setaf 3)'gpg --decrypt ${filename_pwd}'$(tput sgr0) 
    and providing this new passphrase.

(3) There is also a cleartext revocation certificate provided, which you
    might keep in your local .gnupg/ folder on your drive. However, for
    added security it is recommended to unrecoverably delete the unencrypted
    local certificate via 
    $(tput setaf 3)'shred -u ${filename_cleartext}'$(tput sgr0) 
    and only keep the save encrypted one. However, this can be done at any
    later time.

This message is save as a README file in ${HOME}/${DIR} for later reference.

EOF

  cat README
  
  read -p "Press Enter to continue" nothing

  local revoke_choice=1

  cat > gpg_commands <<EOF
y
${revoke_choice}

y
EOF

  gpg --armor --output ${filename_cleartext} --status-fd 2 --command-fd 0 \
  --gen-revoke ${truncated_fingerprint} < gpg_commands

  gpg --armor --output ${filename_pwd} --symmetric \
  --status-fd 2 --command-fd 0 \
  ${filename_cleartext} 

  shred -u gpg_commands
}    # ----------  end of function createRevocationCertificate  ----------

function create_subkeys () {
  local truncated_fingerprint=$(get_master_key_fingerprint | \
    awk '{for (i=7; i<NF; i++) printf $i ""; print $NF}')

  local encrypt_subkey_choice=6
  local encrypt_subkey_length=1024
  #local encrypt_subkey_length=8192
  local encrypt_subkey_expire=6m

  local signing_subkey_choice=4
  local signing_subkey_length=1024
  #local signing_subkey_length=4096
  local signing_subkey_expire=5y

  echo Generating signing and encryption subkeys. Fear not, this might take \
  a while. 
# as enough entropy has to be generate to have a good random \
# number seed.

  cat > gpg_commands <<EOF
addkey
${encrypt_subkey_choice}
${encrypt_subkey_length}
${encrypt_subkey_expire}
addkey
${signing_subkey_choice}
${signing_subkey_length}
${signing_subkey_expire}
save
"
EOF

  gpg --batch --status-fd 2 --command-fd 0 --yes --edit-key \
    ${truncated_fingerprint} < gpg_commands

  shred -u gpg_commands
}    # ----------  end of function create_subkeys  ----------

function export_keys () {
  local truncated_fingerprint=$(get_master_key_fingerprint | \
    awk '{for (i=7; i<NF; i++) printf $i ""; print $NF}')

local filename_sec_subkey="secret-subkeys\
-for-${EMAIL}-${truncated_fingerprint}.asc"
local filename_sec_master="secret-master-key\
-for-${EMAIL}-${truncated_fingerprint}.asc"
local filename_pub="public-keys\
-for-${EMAIL}-${truncated_fingerprint}.asc"

  echo Exporting keys to ${HOME}/${DIR}.
  gpg --batch --yes --armor --output \
    ${filename_sec_subkey} --export-secret-subkeys ${truncated_fingerprint}

  gpg --batch --yes --armor --output \
  ${filename_sec_master} --export-secret-keys ${truncated_fingerprint}

  gpg --batch --yes --armor --output \
  ${filename_pub} --export ${truncated_fingerprint}

  echo Done. 
  cat >>README <<EOF
Now you can import the public keys and the $(tput bold)secret subkeys 
$(tput sgr0)to your regularly used device(s)
$(tput setaf 3)gpg --import ${filename_pub} ${filename_sec_subkey} \
  $(tput sgr0).
The secret part of the master key should be imported into a safe location
($(tput setaf 3)gpg --homedir some/safe/location --import
public-keys.gpg secret-subkeys.gpg secret-master-key.gpg$(tput sgr0))."
EOF

  cat README | tail -6
}    # ----------  end of function export_keys  ----------

function upload_key () {
  local truncated_fingerprint=$(get_master_key_fingerprint | \
    awk '{for (i=7; i<NF; i++) printf $i ""; print $NF}')

	local choice
	read -e -p "Upload public keys to keyserver y/n? (n)" choice
	choice=${choice:-n}
	if [[ ${choice} == y ]]
	then
		gpg --send-key ${truncated_fingerprint}
	fi
}    # ----------  end of function upload_key  ----------


function check_user_intension () {
  local choice
  echo
  read -e -p "For experts only: Remove your secret master key y/n? (n)" choice
  choice=${choice:-n}
  if [[ ${choice} == y ]]
  then
    echo
    read -e -p "\
Have you read https://wiki.debian.org/subkeys before and are aware of the
consequences for your daily usage of gpg when you remove your secret master
key y/n? (n)" choice
    choice=${choice:-n}
    if [[ ${choice} == n ]]
    then
      exit 0
    fi
  fi
}    # ----------  end of function check_user_intension-----

function copy_gnupgdir_to_usbdrive () {
  echo
  echo Please insert usb medium to store your secret master key on.
  read -p "Press Enter to continue..." nothing

  local usb_mountpoint=$(mount | grep media | awk '{print $3}')

  echo
  read -e -p "\
Is your drive mounted under \"${usb_mountpoint}\" y/n? (y)"\
  correctly_mounted 
  if [[ ${correctly_mounted} == y ]]
  then
    cp ${HOME}/${DIR} ${usb_mountpoint}/${DIR}
  else
    echo
    read -e -p "Please provide correct path to usb medium: "\
      usb_mountpoint
    #TODO: Check if mountpoint exist
    cp ${HOME}/${DIR} ${usb_mountpoint}/${DIR}
  fi
}    # ----------  end of function check_user_intension-----

function get_subkey_id () {
  case $1 in
    sign | signing ) 
      readonly local key_number=1 ;;
    encrypt | encrypting ) 
      readonly local key_number=2 ;;
  esac

echo $(gpg --list-secret-keys | \
  grep ssb | \
  awk -v "line=${key_number}" 'NR==line {print $2}' | \
  cut -d/ -f 2)
}    # ----------  end of function get_subkeys-----

function extract_private_master_key () {
  
  local signing_subkeys_id=$(get_subkey_id signing)
  local encrypt_subkeys_id=$(get_subkey_id encrypt)
  local masterkey_id=$(get_master_key_fingerprint | \
    awk '{for (i=7; i<NF; i++) printf $i ""; print $NF}')

  echo ${signing_subkeys_id}
  echo ${encrypt_subkeys_id}

  gpg --export-secret-subkeys ${signing_subkey_id}! ${encrypt_subkey_id}! \
    > subkeys
  gpg --export ${masterkey_id} > pubkeys

  cat > gpg_commands <<EOF
N
EOF

# TODO: still not working
  gpg --delete-secret-key ${masterkey_id} < gpg_commands
  gpg --import pubkeys subkeys

  shred -u gpg_commands
}    # ----------  end of function extract_private_master_key  ----------

function remove_master_key () {
# check_user_intension
# copy_gnupgdir_to_usbdrive
  extract_private_master_key
}    # ----------  end of function remove_master_key  ----------


function set_up_gpg () {
	echo
	echo "$(tput setaf 3) Start setting up gnupg.$(tput sgr0)"
	echo

	is_gpg_installed

	mkdir -p ${HOME}/${DIR}
	cd ${HOME}/${DIR}

	user_input
	create_conf_files

	echo
	echo "$(tput setaf 3) Done setting up gnupg.$(tput sgr0)"
	echo
}  # -----  end of function set_up_gpg  -----


function import_key () {
	echo
	echo "$(tput setaf 3) Importing key.$(tput sgr0)"
	echo

	echo "Function not implemented yet."

	echo
	echo "$(tput setaf 3) Done importing key.$(tput sgr0)"
	echo
}  # -----  end of function import_key  -----

function create_key () {
	set_up_gpg

	echo
	echo "$(tput setaf 3) Start creating key.$(tput sgr0)"
	echo
	create_master_key
	create_master_key_revocation_certificate
	create_subkeys
	export_keys
	upload_key
	remove_master_key
	echo
	echo "$(tput setaf 3) Done creating key.$(tput sgr0)"
	echo
}  # -----  end of function create_key  -----


function main() {
	while true
	do
		clear
		echo
		echo "$(tput setaf 3) --- Setting up a gpg encryption environment ---\
					$(tput sgr0)"
		echo
		echo
		echo " ================="
		echo "       Menu       "
		echo " ================="
		echo
		echo " [1] set up only gpg (no key generation)"
		echo " [2] import existing key"
		echo " [3] set up gpg and generate a new key"
		echo " [4] exit"
		echo
		echo -e " Enter your selection: \c"
		read answer
		case "${answer}" in
			1)	set_up_gpg;;
			2)  import_key;;
			3)  Create_key;;
			4)  exit 0;;
			*)  echo " $(tput setaf 2)wrong choice$(tput sgr0)";;
		esac
		echo
		echo -e " Hit the <return> key to continue or <ctrl>-c to quit. \c"
		read input
	done
}

main "$@"
