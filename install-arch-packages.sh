#===========================================================================
#
#          FILE:  install-arch-packages.sh
# 
#   DESCRIPTION:  Installs all relevant packages to an arch linux build.
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#
#       VERSION:  1.0
#       CREATED:  
#      REVISION:  ---
# 
#         USAGE:  ./install-arch-packages.sh 
# 
#        OUTPUT:  
#
#        AUTHOR:  Frank Milde (fm), frank.milde (at) posteo.de
#       COMPANY:  
#
#===========================================================================

#!/bin/bash

# Enforce Bash strict mode, see
# 'http://redsymbol.net/articles/unofficial-bash-strict-mode/'
set -e          # exit if any command [1] has a non-zero exit status
set -u          # a reference to any variable you havent previously defined
# - with the exceptions of $* and $@ - is an error
set -o pipefail # prevents errors in a pipeline from being masked.
set -o nounset  # Treat unset variables as an error
IFS=$'\n\t'     # meaning full Internal Field Separator - controls what Bash
# calls word splitting
#---------------------------------------------------------------------------
# GLOBALS
#---------------------------------------------------------------------------
CMDLINE_ARGS=${1:-}

#---------------------------------------------------------------------------
# FUNCTIONS
#---------------------------------------------------------------------------
function greeting () {
  clear
  echo 
  echo -e "$(tput setaf 3)
--------------------------------------------------
---  Installing essential Arch Linux packages  ---
--------------------------------------------------
    $(tput sgr0)"
  echo 
}    # ----------  end of function greeting  ----------
function display_core_packages () {
	echo "$(tput setaf 3)Core:     $(tput sgr0)"
	column core-packages.txt
	echo
}  # -----  end of function display_core_packages  -----
function display_addon_packages () {
	echo "$(tput setaf 3)Addon:    $(tput sgr0)"
	column addon-packages.txt
	echo
}  # -----  end of function display_addon_packages  -----
function display_local_packages () {
	echo "$(tput setaf 3)Local    $(tput sgr0)"
	column local-packages.txt
	echo
}  # -----  end of function display_local_packages  -----
function display_all_packages () {
  echo "$(tput setaf 3)Packages: $(tput sgr0)"
	display_core_packages
	display_addon_packages
	display_local_packages
}  # -----  end of function display_all_packages  -----
function usage {
  echo "usage: $(basename ${0}) [--help]"
  echo
	display_core_packages
	display_addon_packages
}    # ----------  end of function usage  ----------

function install_all () {
sudo pacman -Syu
 sudo pacman -S $(< all-packages.txt)
}  # -----  end of function install_all  -----
function install_core () {
sudo pacman -Syu
sudo pacman -S $(< core-packages.txt)
}  # -----  end of function install_core  -----
function install_addon () {
sudo pacman -Syu
sudo pacman -S $(< addon-packages.txt)
}  # -----  end of function install_addon  -----

function install_locals () {
echo "$(tput setaf 2)You should install them yourself$(tput sgr0)"
}  # -----  end of function install_locals  -----

#===  FUNCTION  ============================================================
#          NAME:  main
#   DESCRIPTION:  Runs all functions.
#       GLOBALS:  <++>
#     ARGUMENTS:  <++> 
#       RETURNS:  <++> 
#===========================================================================
function main() {
	while [ "${CMDLINE_ARGS}" != "" ]; 
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

	while true
	do
		clear

		greeting
		display_core_packages
		display_addon_packages

		echo "$(tput setaf 3)=================  $(tput sgr0)"
		echo "$(tput setaf 3)      Menu         $(tput sgr0)"
		echo "$(tput setaf 3)=================  $(tput sgr0)"
		echo
		echo "$(tput setaf 3)[1] Install all    $(tput sgr0)"
		echo "$(tput setaf 3)[2] Install core   $(tput sgr0)"
		echo "$(tput setaf 3)[3] Install addons $(tput sgr0)"
		echo "$(tput setaf 3)[4] Display local  $(tput sgr0)"
		echo "$(tput setaf 3)[5] exit           $(tput sgr0)"
		echo

		local choice
		read -e -p "$(tput setaf 3)Enter your selection:$(tput sgr0)" choice

		case "${choice}" in
			1)	install_all;;
			2)  install_core;;
			3)  install_addon;;
			4)  display_local_packages;;
			5)  exit 0;;
			*)  echo "$(tput setaf 2)Wrong choice.$(tput sgr0)"
		esac  # -----  end of case -----
		echo
		echo -e "$(tput setaf 3)Hit the <return> key to continue or <ctrl>-c to quit.$(tput sgr0)"
		read input
	done

	echo
	echo "$(tput setaf 3)Done.$(tput sgr0)"
}

main "$@"

