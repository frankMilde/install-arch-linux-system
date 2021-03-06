#===========================================================================
#
#          FILE:  encrypt-device.sh
# 
#   DESCRIPTION:  <++>
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#
#       VERSION:  1.0
#       CREATED:  11/23/2014 19:54
#      REVISION:  ---
# 
#         USAGE:  ./encrypt-device.sh 
# 
#        OUTPUT:  <+OUTPUT+>
#
#        AUTHOR:  Frank Milde (fm), frank.milde (at) posteo.de
#       COMPANY:  
#
#===========================================================================

#!/bin/bash

# Enforce Bash strict mode, see
# 'http://redsymbol.net/articles/unofficial-bash-strict-mode/'
set -e          # exit if any command [1] has a non-zero exit status
                # - with the exceptions of $* and $@ - is an error
set -o pipefail # prevents errors in a pipeline from being masked.
#set -o nounset  # Treat unset variables as an error
IFS=$'\n\t'     # meaning full Internal Field Separator - controls what Bash
# calls word splitting

#---------------------------------------------------------------------------
# GLOBALS
#---------------------------------------------------------------------------
FLAG_COMMANDLINE=true
DISK=""

#---------------------------------------------------------------------------
# FUNCTIONS
#---------------------------------------------------------------------------
function greeting () {
echo
echo -e "$(tput setaf 3)
--------------------------
---  Encrypt partition ---
--------------------------
Hit the <return> key to continue or <ctrl>-c to quit.$(tput sgr0)"
	read input
	echo
}    # ----------  end of function greeting  ----------

function usage {
echo "usage: $(basename ${0}) [--help] [-d disk]"
echo "example: $(basename ${0}) -d sda"
echo
}    # ----------  end of function usage  ----------

function user_input () {
  read -e -p "Enter the partition to be encrypted " DISK
}    # ----------  end of function user_input  ----------

#===  FUNCTION  ============================================================
#          NAME:  main
#   DESCRIPTION:  Runs all functions.
#       GLOBALS:  <CURSOR>
#     ARGUMENTS:  <++> 
#       RETURNS:  <++> 
#===========================================================================
function main() {
  if [[ "$1" == "" ]]; then
    FLAG_COMMANDLINE=false
  else
    FLAG_COMMANDLINE=true
    while [ "$1" != "" ]; do
      case $1 in
        -d | --disk ) shift
                      DISK=$1
                      ;;
        -h | --help ) usage
                      exit
                      ;;
        * )           usage
                      exit 1
      esac
      shift
    done
  fi

  greeting

  if [[ ${FLAG_COMMANDLINE} == false ]]; then
    user_input
  fi

	cryptsetup -v --cipher serpent-xts-plain64 --key-size 512 --hash sha512 --iter-time 5000 --use-random luksFormat /dev/${DISK}

echo "$(tput setaf 3)Done.$(tput sgr0)"
}

main "$@"

