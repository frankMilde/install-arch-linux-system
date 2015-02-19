#===========================================================================
#
#          File:  install_firefox_addons.sh
# 
#   Description:  Installs essential firefox addons.
#                 Does not work at the moment
# 
#       Options:  ---
#  Requirements:  wget
#          Bugs:  Firefox does not recognize add-ons.
#         Notes:  This script is based on
#  http://askubuntu.com/questions/73474/how-to-install-firefox-addon-from-command-line-in-scripts
#                 Other sources include
#  http://bernaerts.dyndns.org/linux/74-ubuntu/271-ubuntu-firefox-thunderbird-addon-commandline
#  http://kb.mozillazine.org/Installing_extensions
#  http://forums.mozillazine.org/viewtopic.php?t=220787
#  "https://stackoverflow.com/questions/10031046/method-to-install-multiple-firefox-extensions-or-addons-in-with-least-user-inter
#
#       Version:  1.0
#       Created:  01/18/2014 10:01:49 AM CET
#      Revision:  ---
# 
#         Usage:  ./install_firefox_addons.sh 
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
----------------------------------------------
---  Installing essential firefox add-ons  ---
----------------------------------------------
    $(tput sgr0)"
  echo 
}    # ----------  end of function greeting  ----------

function display_addons () {
  echo "Add-ons:"
  echo "         Adblock Edge"
  echo "         Disconnect"
  echo "         Download Statusbar Fixed"
  echo "         DownloadHelper"
  echo "         Ghostery"
  echo "         Greasemonkey"
  echo "         Hola"
  echo "         HTTPS Everywhere"
	echo "         Leech Block"
  echo "         LEO Search"
	echo "         Nuke Anything Enhanced"
	echo "         Re-Pagination"
  echo "         RequestPolicy"
  echo "         Tab Mix Plus"
  echo "         Xmarks"
  echo "         Youtube High Definition"
	echo
}  # -----  end of function display_addons  -----

function usage {
  echo "usage: $(basename ${0}) [--help]"
  echo
	display_addons
}    # ----------  end of function usage  ----------


function kill_firefox () {
	echo "$(tput bold)$(tput setaf 1)Killing firefox.$(tput sgr0)" 
	echo "If you have no automatic session-restore enabled, please save your tabs."
  sleep 1
	echo
  read -p "Press Enter to continue, or abort by pressing Ctrl-c"
	killall firefox > /dev/null 2>&1
}  # -----  end of function kill_firefox  -----

function install_addons () {
    local choice
		local baseURL="addons.mozilla.org/firefox/downloads/latest/"
    read -e -p "Install all add-ons y/n? (y) " choice
    choice=${choice:-y}
    if [[ ${choice} == y ]]
    then
			echo
			echo "Install:"
			echo "         Adblock Edge"
			wget "https://${baseURL}394968/addon-394968-latest.xpi" >/dev/null 2>&1
			echo "         Disconnect"
			wget "https://${baseURL}464050/addon-464050-latest.xpi" >/dev/null 2>&1
			echo "         Download Statusbar Fixed"
			wget "https://${baseURL}469318/addon-469318-latest.xpi" >/dev/null 2>&1
			echo "         DownloadHelper"
			wget "https://${baseURL}3006/addon-3006-latest.xpi" >/dev/null 2>&1
			echo "         Ghostery"
			wget "https://${baseURL}9609/addon-9609-latest.xpi" >/dev/null 2>&1
			echo "         Greasemonkey"
			wget "https://${baseURL}748/addon-748-latest.xpi" >/dev/null 2>&1
			echo "         Hola"
			wget "https://hola.org/firefox_latest.xpi" >/dev/null 2>&1
			echo "         HTTPS Everywhere"
			wget "https://www.eff.org/files/https-everywhere-latest.xpi" >/dev/null 2>&1
			echo "         Leech Block"
			wget "https://${baseURL}4476/addon-4476-latest.xpi" >/dev/null 2>&1
			echo "         LEO Search"
			wget "https://${baseURL}984/addon-984-latest.xpi" >/dev/null 2>&1
			echo "         Nuke Anything Enhanced"
			wget "https://${baseURL}951/addon-951-latest.xpi" >/dev/null 2>&1
			echo "         Re-Pagination"
			wget "https://${baseURL}2099/addon-2099-latest.xpi" >/dev/null 2>&1
			echo "         RequestPolicy"
			wget "https://www.requestpolicy.com/releases/requestpolicy-1.x.xpi" >/dev/null  2>&1
			echo "         Tab Mix Plus"
			wget "https://${baseURL}1122/addon-1122-latest.xpi" >/dev/null 2>&1
			echo "         Xmarks"
			wget "https://${baseURL}2410/addon-2410-latest.xpi" >/dev/null 2>&1
			echo "         Youtube High Definition"
			wget "https://${baseURL}328839/addon-328839-latest.xpi" >/dev/null 2>&1
		else
			echo
			echo "Install:"
			read -e -p "         Adblock Edge (y/n)? (y) " choice
			choice=${choice:-y}
			if [[ ${choice} == y ]]; then
				wget "https://${baseURL}394968/platform:2/addon-394968-latest.xpi" >/dev/null 2>&1
			fi

			read -e -p "         Disconnect (y/n)? (y) " choice
			choice=${choice:-y}
			if [[ ${choice} == y ]]; then
				wget "https://${baseURL}464050/addon-464050-latest.xpi" >/dev/null 2>&1
			fi

			read -e -p "         Download Statusbar Fixed (y/n)? (y) " choice
			choice=${choice:-y}
			if [[ ${choice} == y ]]; then
				wget "https://${baseURL}469318/addon-469318-latest.xpi" >/dev/null 2>&1
			fi

			read -e -p "         DownloadHelper (y/n)? (y) " choice
			choice=${choice:-y}
			if [[ ${choice} == y ]]; then
				wget "https://${baseURL}3006/addon-3006-latest.xpi" >/dev/null 2>&1
			fi

			read -e -p "         Ghostery (y/n)? (y) " choice
			choice=${choice:-y}
			if [[ ${choice} == y ]]; then
				wget "https://${baseURL}9609/addon-9609-latest.xpi" >/dev/null 2>&1
			fi

			read -e -p "         Greasemonkey (y/n)? (y) " choice
			choice=${choice:-y}
			if [[ ${choice} == y ]]; then
				wget "https://${baseURL}748/addon-748-latest.xpi" >/dev/null 2>&1
			fi

			read -e -p "         Hola (y/n)? (y) " choice
			choice=${choice:-y}
			if [[ ${choice} == y ]]; then
				wget "https://hola.org/firefox_latest.xpi" >/dev/null 2>&1
			fi

			read -e -p "         HTTPS Everywhere (y/n)? (y) " choice
			choice=${choice:-y}
			if [[ ${choice} == y ]]; then
				wget "https://www.eff.org/files/https-everywhere-latest.xpi" >/dev/null 2>&1
			fi

			read -e -p "         Leech Block (y/n)? (y) " choice
			choice=${choice:-y}
			if [[ ${choice} == y ]]; then
				wget "https://${baseURL}4476/addon-4476-latest.xpi" >/dev/null 2>&1
			fi

			read -e -p "         LEO Search (y/n)? (y) " choice
			choice=${choice:-y}
			if [[ ${choice} == y ]]; then
				wget "https://${baseURL}984/addon-984-latest.xpi" >/dev/null  2>&1
			fi

			read -e -p "         Nuke Anything Enhanced (y/n)? (y) " choice
			choice=${choice:-y}
			if [[ ${choice} == y ]]; then
				wget "https://${baseURL}951/addon-951-latest.xpi" >/dev/null 2>&1
			fi

			read -e -p "         Re-Pagination (y/n)? (y) " choice
			choice=${choice:-y}
			if [[ ${choice} == y ]]; then
				wget "https://${baseURL}2099/addon-2099-latest.xpi" >/dev/null 2>&1
			fi

			read -e -p "         RequestPolicy (y/n)? (y) " choice
			choice=${choice:-y}
			if [[ ${choice} == y ]]; then
				wget "https://www.requestpolicy.com/releases/requestpolicy-1.x.xpi" >/dev/null  2>&1
			fi

			read -e -p "         Tab Mix Plus (y/n)? (y) " choice
			choice=${choice:-y}
			if [[ ${choice} == y ]]; then
				wget "https://${baseURL}1122/addon-1122-latest.xpi" >/dev/null 2>&1
			fi

			read -e -p "         Xmarks (y/n)? (y) " choice
			choice=${choice:-y}
			if [[ ${choice} == y ]]; then
				wget "https://${baseURL}2410/addon-2410-latest.xpi" >/dev/null 2>&1
			fi

			read -e -p "         Youtube High Definition (y/n)? (y) " choice
			choice=${choice:-y}
			if [[ ${choice} == y ]]; then
				wget "https://${baseURL}328839/addon-328839-latest.xpi" >/dev/null 2>&1
			fi
		fi

		firefox *.xpi && 
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
	kill_firefox
	install_addons

	echo
	echo "Done."
}

main "$@"
