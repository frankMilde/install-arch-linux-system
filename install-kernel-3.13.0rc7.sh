#===========================================================================
#
#          File:  install-kernel-3.13.0rc7.sh
# 
#   Description:  Installs the 3.13.0 rc7 kernel to a linux ubuntu/mint
#                 system. The script is based on
#                 http://www.upubuntu.com/2013/12/installupgrade-to-linux-kernel-3126-in.html 
# 
#       Options:  None
#  Requirements:  wget, dpkg
#         Notes:  works only on i386,i686, and amd_64 architectures.
#          Bugs:  run-parts: executing /etc/kernel/postinst.d/dkms 3.13.0-031300rc7-generic /boot/vmlinuz-3.13.0-031300rc7-generic
#                 Error! Bad return status for module build on kernel: 3.13.0-031300rc7-generic (x86_64)
#                 Consult /var/lib/dkms/virtualbox-guest/4.2.16/build/make.log for more information.
#
#       Version:  1.0
#       Created:  01/07/2014 04:15:37 PM CET
#      Revision:  ---
# 
#         Usage:  sudo ./install-kernel-3.13.0rc7.sh 
# 
#        Output:  None
#
#        Author:  Frank Milde (FM), frank.milde (at) posteo.de
#       Company:  
#
#===========================================================================
#!/bin/bash

#---------------------------------------------------------------------------
# globals
#---------------------------------------------------------------------------
ARCH=$(uname -m)
DIR=kernel-temp

#---------------------------------------------------------------------------
# USER INTERFACE
#---------------------------------------------------------------------------
echo "$(tput setaf 3)--- Kernel 3.13.0 rc7 will be installed in an ${ARCH} \
system ---$(tput sgr0)"
echo ""

sleep 2

read -p "Press Enter to continue, or abort by pressing CTRL+C" nothing

echo ""
echo ""


#---------------------------------------------------------------------------
# links
#---------------------------------------------------------------------------
LINK1="http://kernel.ubuntu.com/~kernel-ppa/mainline/v3.13-rc7-trusty/linux-headers-3.13.0-031300rc7_3.13.0-031300rc7.201401041835_all.deb"

# i386 architecture
LINK2="http://kernel.ubuntu.com/~kernel-ppa/mainline/v3.13-rc7-trusty/linux-headers-3.13.0-031300rc7-generic_3.13.0-031300rc7.201401041835_i386.deb"
LINK3="http://kernel.ubuntu.com/~kernel-ppa/mainline/v3.13-rc7-trusty/linux-image-3.13.0-031300rc7-generic_3.13.0-031300rc7.201401041835_i386.deb"

# amd64 architecture
LINK4="http://kernel.ubuntu.com/~kernel-ppa/mainline/v3.13-rc7-trusty/linux-headers-3.13.0-031300rc7-generic_3.13.0-031300rc7.201401041835_amd64.deb"
LINK5="http://kernel.ubuntu.com/~kernel-ppa/mainline/v3.13-rc7-trusty/linux-image-3.13.0-031300rc7-generic_3.13.0-031300rc7.201401041835_amd64.deb"

#---------------------------------------------------------------------------
# install procedure
#---------------------------------------------------------------------------
mkdir -p ${HOME}/${DIR}
cd ${HOME}/${DIR}

wget -c ${LINK1}

if  [ ${ARCH} = i686 ] || [ ${ARCH} = i386 ]; then
  wget -c ${LINK2}
  wget -c ${LINK3}
elif [ ${ARCH} = "x86_64" ]; then
  wget -c ${LINK4}
  wget -c ${LINK5}
else
  echo "Failed to install: \
  $(tput setaf 3) Unsupported Architecture ${ARCH} $(tput sgr0)"
fi

if  [ ${ARCH} = i686 ] || [ ${ARCH} = i386 ] || [ ${ARCH} = "x86_64" ]; then
  sudo -s dpkg -i *.deb  
  sudo -s update-grub 
fi

cd ${HOME}

sudo -s rm -rf ${HOME}/${DIR}
