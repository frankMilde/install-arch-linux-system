#===========================================================================
#
#          File:  setup-ssh-without-password.sh
# 
#   Description:  Setting up ssh to use with out passwords using an RSA key
#                 pair.
# 
#       Options:  ---
#  Requirements:  bash shell, openssh, scp
#          Bugs:  - Does NOT check if entry in server authenticatedKeys
#                   already exist.
#                 - Does NOT work under ash shell.
#         Notes:  This script automates the process described in
#                 http://csua.berkeley.edu/%7Eranga/notes/ssh_nopass.html
#
#                 If ssh-copy-id is installed the same can be done via:
#                 ssh-keygen
#                 ssh-copy-id -i ~/.ssh/id_rsa.pub your.remote.host
#
#                 for more information see:
#                 http://www.thegeekstuff.com/2008/11/3-steps-to-perform-ssh-login-without-password-using-ssh-keygen-ssh-copy-idI
#                 
#       Version:  1.1
#       Created:  11/22/13 13:19:06 UTC
#      Revision:  Tue Jan 14 17:55:27 2014
#                 - added user interface
#                 - added option handling
#                 - added greeting
# 
#         Usage:  ./setup-ssh-without-password.sh 
#                 All arguments are optional.
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
readonly KEY="remotessh_rsa"
readonly CLIENTCONFIGFILE="${HOME}/.ssh/config"

FLAG_COMMANDLINE=true
USER=yourUserName
HOST="your.remote.server"


#---------------------------------------------------------------------------
#   functions
#---------------------------------------------------------------------------
function greeting () {
  clear
  echo 
  echo "$(tput setaf 3)
--- Setting up ssh to use with out passwords using an RSA key pair ---\
    $(tput sgr0)"
  echo 
  sleep 1
  read -p "Press Enter to continue, or abort by pressing Ctrl-c" nothing
  clear
  echo 
  echo "$(tput setaf 3) \
--- Setting up ssh to use with out passwords using an RSA key pair ---\
    $(tput sgr0)"
  echo 
}    # ----------  end of function greeting  ----------

function user_input () {
  read -e -p "Enter your remote host address : " HOST
  read -e -p "Enter your remote user name    : " USER
}    # ----------  end of function user_input  ----------

function usage {
  echo "usage: $(basename ${0}) [[--user your-remote-user-name] | \
[--host your-remote-host-address] | [--help]]"
  echo
  echo "All arguments are optional."
}    # ----------  end of function usage  ----------

function create_key_pair_on_client() {
  echo "Create key pair. This might take a while."
  mkdir -p ${HOME}/.ssh
  chmod 0700 ${HOME}/.ssh
  ssh-keygen -t rsa -f ${HOME}/.ssh/${KEY} -P '' >/dev/null
}    # ----------  end of function create_key_pair_on_client  ----------

function copy_pubKey_to_server() {
  echo "Copy public keys to server"
  scp ${HOME}/.ssh/${KEY}.pub ${USER}@${HOST}:.
}    # ----------  end of function copy_pubKey_to_server  ----------

function add_to_servers_auth_keys() {
  echo "Add public keys to server's authorized_keys."

  ssh ${USER}@${HOST} << ENDSSH
  cat ${KEY}.pub >> ~/.ssh/authorized_keys2; 
  chmod 0600 ~/.ssh/authorized_keys2 
  cat ${KEY}.pub >> ~/.ssh/authorized_keys 
  chmod 0600 ~/.ssh/authorized_keys;
  /bin/rm ${KEY}.pub
ENDSSH
}    # ----------  end of function add_to_servers_auth_keys  ----------

function add_to_client_config() {
  echo "Update clients ssh config file."

  if [[ ! -e ${CLIENTCONFIGFILE} ]]
  then
    touch ${HOME}/.ssh/config
    echo Host ${HOST} >> ${HOME}/.ssh/config
  fi

  echo -e "\t IdentityFile ~/.ssh/${KEY} " >> ${HOME}/.ssh/config
}    # ----------  end of function add_to_client_config  ----------

function main() {
  if [[ "$1" == "" ]]; then
    FLAG_COMMANDLINE=false
  else
    FLAG_COMMANDLINE=true
    while [ "$1" != "" ]; do
      case $1 in
        -u | --user ) shift
                      USER=$1
                      ;;
        --host )      shift
                      HOST=$1
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

  create_key_pair_on_client
  copy_pubKey_to_server
  add_to_servers_auth_keys
  add_to_client_config

  echo Done.
}    # ----------  end of function main  ----------

main "$@"
