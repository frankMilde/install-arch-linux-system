#===========================================================================
#
#          FILE:  secure-wipe-entire-disk.sh
# 
#   DESCRIPTION:  Running this script will wipe our disk clean by
#                 overwriting the entire drive or partition with a stream of
#                 random bytes
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#
#       VERSION:  1.0
#       CREATED:  11/23/2014 19:06
#      REVISION:  ---
# 
#         USAGE:  ./secure-wipe-entire-disk.sh 
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
------------------------------------------------------
---  Securely wipe all data from disk or partition ---
------------------------------------------------------
$(tput sgr0)"
echo
}    # ----------  end of function greeting  ----------

function usage {
echo "usage: $(basename ${0}) [--help] [-d disk]"
echo "example: $(basename ${0}) -d sda"
echo
}    # ----------  end of function usage  ----------

function user_input () {
  read -e -p "Enter the disk or partition to be wiped: " DISK
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

	DATA_SIZE=$(df -h  /dev/${DISK} | tail -n1 | tr -s ' ' | cut -d' ' -f2)
	
echo -e "$(tput bold)All ${DATA_SIZE} OF DATA WILL BE LOST!$(tput sgr0)$(tput setaf 3)

Hit the <return> key to continue or <ctrl>-c to quit.$(tput sgr0)"
	read input

	openssl enc -aes-256-ctr -pass pass:"$(dd if=/dev/random bs=128 count=1 2\
		> /dev/null | base64)" -nosalt </dev/zero \
		> /dev/${DISK}

echo
echo "$(tput setaf 3)Done.$(tput sgr0)"
}

main "$@"

