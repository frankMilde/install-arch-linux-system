#===========================================================================
#
#          File:  install_thunderbird_addons.sh
# 
#   Description:  Installs essential thunderbird addons.
#                 Does not work at the moment
# 
#       Options:  ---
#  Requirements:  wget
#          Bugs:  ---
#         Notes:  ---
#
#       Version:  1.0
#       Created:  Thu Nov 13 01:33:21 2014
#      Revision:  ---
# 
#         Usage:  ./install_thunderbird_addons.sh 
# 
#        Output:  <+OUTPUT+>
#
#        Author:  Frank Milde (FM), frank.milde (at) posteo.de
#       Company:
#
#===========================================================================

#!/bin/bash

function greeting () {
  clear
  echo 
  echo -e "$(tput setaf 3)
--------------------------------------------------
---  Installing essential thunderbird add-ons  ---
--------------------------------------------------
    $(tput sgr0)"
  echo 
}    # ----------  end of function greeting  ----------


function display_addons () {
  echo "Add-ons:"
  echo "         Enigmail"
  echo "         External Editor"
  echo "         Lightning"
  echo "         Markdown Here"
	echo
}  # -----  end of function display_addons  -----

function usage {
  echo "usage: $(basename ${0}) [--help]"
  echo
	display_addons
}    # ----------  end of function usage  ----------


function kill_thunderbird () {
	echo "$(tput bold)$(tput setaf 1)Killing thunderbird.$(tput sgr0)" 
	echo "If you have open email drafts, please save or close them."
  sleep 1
	echo
  read -p "Press Enter to continue, or abort by pressing Ctrl-c"
	killall thunderbird > /dev/null 2>&1
}  # -----  end of function kill_thunderbird  -----


function install_addons () {
	local baseURL="addons.mozilla.org/thunderbird/downloads/latest/"
	local choice
	read -e -p "Install all add-ons y/n? (y)" choice
	choice=${choice:-y}
	if [[ ${choice} == y ]]
	then
		echo
		echo "Install:"
		echo "         Enigmail"
		wget "https://${baseURL}71/addon-71-latest.xpi"  >/dev/null 2>&1
		echo "         External Editor"
		wget globs.org/file/exteditor_v100.xpi >/dev/null 2>&1
		echo "         Lightning"
		wget "https://${baseURL}2313/platform:2/addon-2313-latest.xpi" >/dev/null 2>&1
		echo "         Markdown Here"
	else
		echo
		echo "Install:"
		read -e -p "         Enigmail (y/n)? (y)" choice
		choice=${choice:-y}
		if [[ ${choice} == y ]]; then
			wget "https://${baseURL}71/addon-71-latest.xpi"  >/dev/null 2>&1
		fi

		read -e -p "         External Editor (y/n)? (y)" choice
		choice=${choice:-y}
		if [[ ${choice} == y ]]; then
			wget globs.org/file/exteditor_v100.xpi >/dev/null 2>&1
		fi

		read -e -p "         Lightning (y/n)? (y)" choice
		choice=${choice:-y}
		if [[ ${choice} == y ]]; then
			wget "https://${baseURL}2313/platform:2/addon-2313-latest.xpi" >/dev/null 2>&1
		fi

		read -e -p "         Markdown Here (y/n)? (y)" choice
		choice=${choice:-y}
		if [[ ${choice} == y ]]; then
			wget "https://${baseURL}375281/addon-375281-latest.xpi" >/dev/null 2>&1
		fi
	fi

	thunderbird *.xpi && 
 	rm *.xpi
}  # -----  end of function install_addons  -----

function main() {
	while [ "$1" != "" ]; 
	do
		case $1 in
			-h | --help ) usage
				exit
				;;
			* )           usage
				exit 1
		esac  # -----  end of case -----
		shift
	done  # -----  end of while  -----

  greeting
	display_addons
	kill_thunderbird
	install_addons

	echo
	echo "Done."
	echo
	echo "Remark:"
	echo "        For external editor to work, disable html text composition in account settings of each mailbox."
}

main "$@"
