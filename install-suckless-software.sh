#===========================================================================
#
#          FILE:  install-suckless-software.sh
# 
#   DESCRIPTION:  This script will install the latest suckless software. For
#   							more see:
#									http://suckless.org
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#
#       VERSION:  1.0
#       CREATED:  Tue Nov 18 16:02:41 2014
#      REVISION:  ---
# 
#         USAGE:  ./install-suckless-software.sh 
# 
#        OUTPUT:  None
#
#        AUTHOR:  Frank Milde (fm), frank.milde (at) posteo.de
#       COMPANY:  
#
#===========================================================================

#!/bin/bash

# Enforce Bash strict mode, see {{{
# 'http://redsymbol.net/articles/unofficial-bash-strict-mode/' 
set -e 					# exit if any command [1] has a non-zero exit status
set -u 					# a reference to any variable you havent previously defined
								# - with the exceptions of $* and $@ - is an error
set -o pipefail # prevents errors in a pipeline from being masked.
set -o nounset  # Treat unset variables as an error
IFS=$'\n\t'     # meaning full Internal Field Separator - controls what Bash calls word
								# splitting }}}

#---------------------------------------------------------------------------
# USER INTERFACE
#---------------------------------------------------------------------------
readonly SL_SOFTWARE=(
"dwm"
"dmenu"
"st"
"slock"
# add further software here
)

readonly DWM_PATCHES=(
"bstack"
"attachaside"
# add further patches here
)

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
------------------------------------------------
---  Installing essential suckless software  ---
------------------------------------------------
           $(tput sgr0)"
  echo 
}    # ----------  end of function greeting  ----------
function display_software () {
  echo "Software:"

	for software in ${SL_SOFTWARE[@]}; do
		echo -e "         ${software}"
	done  # -----  end of for  -----

	echo
}  # -----  end of function display_software -----
function usage {
  echo "usage: $(basename ${0}) [--help]"
  echo
	display_software
}    # ----------  end of function usage  ----------
function create_dir () {
echo -e "$(tput setaf 3)Creating directories.$(tput sgr0)"
	mkdir -p ${HOME}/local/src
	mkdir -p ${HOME}/local/bin
}  # -----  end of function create_dir  -----
function download_software () {
	cd ${HOME}/local/src/

	local readonly baseURL="git://git.suckless.org/"

	for software in ${SL_SOFTWARE[@]}; do
		echo -e "$(tput setaf 3)Fetching ${software} $(tput sgr0)"
		git clone --depth=1 -q ${baseURL}${software}
	done  # -----  end of for  -----
}  # -----  end of function download_software  -----

#---  FUNCTION  ------------------------------------------------------------
#          NAME:  apply_dwm_patches
#   DESCRIPTION:  
#       GLOBALS:  DWM_PATCHES
#     ARGUMENTS:  None 
#       RETURNS:  None 
#---------------------------------------------------------------------------
function apply_dwm_patches () {
	cd ${HOME}/local/src/dwm

	for patch in ${DWM_PATCHES[@]}; do
		local latest_patch_version=$(find_latest_available_patch_version ${patch})

		echo -e "$(tput setaf 3)Apply dwm-${latest_patch_version}-${patch}.diff $(tput sgr0)"

		wget --quiet \
		"http://dwm.suckless.org/patches/dwm-${latest_patch_version}-${patch}.diff"

		#git apply dwm-${latest_patch_version}-${patch}.diff
		patch < dwm-${latest_patch_version}-${patch}.diff
	done  # -----  end of for  -----

	echo -e "$(tput setaf 3) Apply dwm-6.0-config.diff $(tput sgr0)"

	cp ${HOME}/github/install-arch-linux-system/dwm-6.0-config.diff .
	patch -p1 < dwm-6.0-config.diff
}  # -----  end of function apply_dwm_patches  -----

#---  FUNCTION  ------------------------------------------------------------
#          NAME:  find_latest_available_patch_version
#   DESCRIPTION:  
#       GLOBALS:  None
#     ARGUMENTS:  patch name 
#       RETURNS:  latest available version of patch, i.e. "6.0"
#---------------------------------------------------------------------------
function find_latest_available_patch_version () {
  local readonly patch_name=$1	

	cd ${HOME}/local/src/dwm

	local readonly dwm_version=$(cat config.mk | grep "VERSION = " | awk '{print $3}')
	local latest_patch_version=${dwm_version}
	local readonly lower_version_number="0.1"

	set +e # allow non-zero return values
	wget --spider --quiet \
	"http://dwm.suckless.org/patches/dwm-${dwm_version}-${patch_name}.diff"
	local return_val="$?"

	while  [[ "${return_val}" == "8" ]] ; do
		latest_patch_version=$(echo ${latest_patch_version} - ${lower_version_number} | bc -l)
		wget --spider --quiet \
		"http://dwm.suckless.org/patches/dwm-${latest_patch_version}-${patch_name}.diff"
		return_val=$?
	done  # -----  end of while  -----

	set -e

	echo ${latest_patch_version}
}  # -----  end of function find_latest_available_patch_version  -----

function apply_suckless_patches () {
	echo -e "$(tput setaf 3)Apply config patches.$(tput sgr0)"

	cd ${HOME}/local/src/
	cp ${HOME}/github/install-arch-linux-system/suckless.diff .

	#set +e # allow non-zero return values
	patch -p1 < suckless.diff
	#set -e
}  # -----  end of function apply_suckless_patches  -----
function install_software () {
	cd ${HOME}/local/src/

	for software in ${SL_SOFTWARE[@]}; do
		echo -e "$(tput setaf 3)Installing ${software} $(tput sgr0)"
		cd ${software}
		make clean install
		cd ..
	done  # -----  end of for  -----
}  # -----  end of function install_software  -----

#===  FUNCTION  ============================================================
#          NAME:  main
#   DESCRIPTION:  Runs all functions.
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

  greeting
	display_software

	local choice=""
	read -e -p "Install all software y/n? (default is y) " choice
	choice=${choice:-y}

	if [[ ${choice} == y ]]
	then
		create_dir
		download_software
		apply_dwm_patches
		apply_suckless_patches
		install_software
	else
		echo "
$(tput setaf 3)
Then modify $(tput bold)$(basename ${0}) $(tput sgr0)$(tput setaf 3 )in the USERINTERFACE section in 
the begining of the file and comment out the software or dwm patches you
would not like to have installed.
$(tput sgr0)"
	fi

	echo
	echo -e "$(tput setaf 3)Done.$(tput sgr0)"
}

main "$@"
