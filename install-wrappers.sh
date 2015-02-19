#===========================================================================
#
#          FILE:  install-wrappers.sh
# 
#   DESCRIPTION:  Copies the different wrapper scripts to ~/local/bin
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
#         USAGE:  ./install-wrappers.sh 
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
set -u          # a reference to any variable you havent previously defined
# - with the exceptions of $* and $@ - is an error
set -o pipefail # prevents errors in a pipeline from being masked.
set -o nounset  # Treat unset variables as an error
IFS=$'\n\t'     # meaning full Internal Field Separator - controls what Bash     calls word
# splitting

cd
mkdir -p .Trash
mkdir -p local
mkdir -p local/bin
cd ~/github/install-arch-linux-system/ 
cp *-wrapper.sh ~/local/bin
