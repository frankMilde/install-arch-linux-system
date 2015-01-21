Installer
=========

This repository includes some useful shell scripts to set up an Arch Linux
systems with my customizations.

Some nice how-tos can be found
[here](http://www.r11networks.com/2013/01/arch-linux-installation-part-1/)
and
[here](http://lifehacker.com/5680453/build-a-killer-customized-arch-linux-installation-and-learn-all-about-linux-in-the-process)

Arch-Linux Install Walkthrough
==============================

For my laptop I want to achieve the following setup:
```
+--------------------------------------------------------------------------+ +----------------+
| Logical volume1        | Logical volume2        | Logical volume3        | |                |
| /dev/MyStorage/swapvol | /dev/MyStorage/rootvol | /dev/MyStorage/homevol | | Boot partition |
|_ _ _ _ _ _ _ _ _ _ _ _ |_ _ _ _ _ _ _ _ _ _ _ _ |_ _ _ _ _ _ _ _ _ _ _ _ | | (may be on     |
|                                                                          | | other device)  |
|                         LUKS encrypted partition                         | |                |
|                           /dev/sdaX                                      | | /dev/sdbY      |
+--------------------------------------------------------------------------+ +----------------+
```
This is needed to have an encrypted disk, while still being able to go into
suspension mode on the laptop (hence the swap volume).

Get Arch
--------
Get latest Arch distro.
Creating a bootable thumb drive.
Boot your machine with said thumb drive
You are welcomed by a promt as root.

### Check your architeture (32 vs 64 bit)
```
grep -o -w 'lm' /proc/cpuinfo | sort -u
```
if this gives you `lm` as output your machine is 64 bit. Now you know, which
arch type to use at boot (the iso always contains both versions).

Prepare the hard drive
----------------------

### Checking which device your harddrive is
```
$ fdisk -l

Disk /dev/sda: 107.4 GB, 107374182400 bytes, 209715200 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk identifier: 0x5698d902

   Device Boot     Start         End     Blocks   Id  System
/dev/sda1           2048    31459327   15728640   83   Linux
/dev/sda2       31459328   209715199   89127936   83   Linux

Disk /dev/sdb: 4.8 GiB, 50010786 bytes, 97677 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0x74c367a7

Device     Boot Start       End   Sectors   Size Id Type
/dev/sdb1          63   7768064   9767002   4.8G  c W95 FAT32 (LBA)

```
This tells us that `/dev/sda/` is the hard drive and `/dev/sdb/` is the
thumb drive.

### Clear existing harddrive partitions
```
$ sgdisk --zap-all /dev/sda
```
Don't get discouraged by the message `Found invalid GPT and valid MBR;
converting MBR to GPT format in memory`. Its all good.

### Securely wipe all data from disk
Before setting up disk encryption on a disk, [wipe it securely
first](https://wiki.archlinux.org/index.php/Disk_encryption#Preparing_the_disk).
This consists of overwriting the entire drive or partition with a stream of
random bytes, and is done for one or both of the following reasons:
- prevent recovery of previously stored data
- prevent disclosure of usage patterns on the encrypted drive
This way, no unauthorized person can know which and how many sectors actually
contain encrypted data.

When preparing a drive for full-disk encryption, sourcing high quality
entropy is usually not necessary. The alternative is to use an encrypted
datastream. For example, if you will use `AES` for your encrypted partition,
you would wipe it with an equivalent encryption cipher prior to creating the
filesystem to make the empty space not distinguishable from the used space. 
```
$ openssl enc -aes-256-ctr -pass pass:"$(dd if=/dev/random bs=128 count=1 2>/dev/null | base64)" -nosalt </dev/zero \
> /dev/<yourdrive>
```
The above command creates a 128 byte encryption key seeded from
`/dev/urandom`.  `AES-256` in `CTR mode` is used to encrypt `/dev/zero`'s
output with the `urandom` key and writing it to `/dev/sda` for example..
Utilizing the cipher instead of a pseudorandom source results in very high
write speeds and the result is a device filled with AES ciphertext. However,
depending on CPU power and disk size this task can still take a few hours
time.

### Create new harddrive partitions

To achieve our setup we need two partitions, one for `/boot` as it cannot be
encrypted, and second one that will host the encrypted `LUKS` partition under
which the LVMs run. This setup is called **LVM on LUKS** as first everything
is encrypted and then under the encryption the logical volumes created.
We use [fdisk](http://tldp.org/HOWTO/Partition/fdisk_partitioning.html)
([more info on fdisk usage](https://wiki.archlinux.org/index.php/Beginners%27_guide/Preparation#Using_fdisk_to_create_MBR_partitions))
as our tool of choice:
```
$ fdisk /dev/sda
```

#### First we create a `256MB` Boot partition.
```
Command (m for help): <b>n<\b>
Command action
   e   extended
   p   primary partition (1-4)
<b>p</b>
Partition number (1-4): <b>1</b>
First sector (2048-209715199, default 2048):<RETURN>
Using default value 1
Last sector, +sectors or +size{K,M,G,T,P} (31459328-209715199....., default 209715199): +256M
```
Make this partition bootable
```
Command (m for help): a
Partition number (1-4): 1
```
#### Second the rest of the hard drive is use for the encrypted system.
```
Command (m for help): <b>n</b>
Command action
   e   extended
   p   primary partition (1-4)
<b>p</b>
Partition number (1-4): <b>2</b>
First sector (52488-209715199, default 52488):<RETURN>
Using default value 1
Last sector, +sectors or +size{K,M,G,T,P} (31459328-209715199....., default 209715199):<RETURN>
```
Make this partition an LVM
```
Command (m for help): <b>t</b>
Partition number (1-4): <b>2</b>
Hex code (type L to list codes): <b>8e</b>
Changed system type of partition 2 to 8e (Linux LVM)      
Command (m for help): <b>p</b>
```
Create partition by writing partition table
```
Command (m for help):<b>w</b>
```

Encrypt all the things
----------------------

### Check which cipher works best for your machine
Different cpu optimatization might lead to different results on your setup,
but this here suggests, that the `serpent-xts` cipher works best
```
$cryptsetup benchmark
# Tests are approximate using memory only (no storage IO).
PBKDF2-sha1       794375 iterations per second
PBKDF2-sha256     500274 iterations per second
PBKDF2-sha512     364088 iterations per second
PBKDF2-ripemd160  474039 iterations per second
PBKDF2-whirlpool  161022 iterations per second
#  Algorithm | Key |  Encryption |  Decryption
     aes-cbc   128b   139.8 MiB/s   182.0 MiB/s
 serpent-cbc   128b    54.3 MiB/s   228.0 MiB/s
 twofish-cbc   128b   148.8 MiB/s   202.3 MiB/s
     aes-cbc   256b   121.6 MiB/s   136.9 MiB/s
 serpent-cbc   256b    58.2 MiB/s   226.6 MiB/s
 twofish-cbc   256b   153.1 MiB/s   202.0 MiB/s
     aes-xts   256b   171.2 MiB/s   172.8 MiB/s
 serpent-xts   256b   206.2 MiB/s   211.1 MiB/s
 twofish-xts   256b   181.3 MiB/s   187.5 MiB/s
     aes-xts   512b   132.3 MiB/s   131.6 MiB/s
<b> serpent-xts   512b   206.9 MiB/s   214.7 MiB/s</b>
 twofish-xts   512b   186.6 MiB/s   188.4 MiB/s
```
We want the best possible security so we choose to use the following
[options](https://wiki.archlinux.org/index.php/Dm-crypt/Device_encryption#Encryption_options_for_LUKS_mode).
```
cryptsetup -v --cipher serpent-xts-plain64 --key-size 512 --hash sha512 --iter-time 5000 --use-random luksFormat /dev/sda2
```
Open the container: 
```
cryptsetup open --type luks /dev/sda2 lvm
```
The decrypted container is now available at `/dev/mapper/lvm`.

### Preparing the logical volumes

Create a physical volume on top of the opened LUKS container: 
```
pvcreate /dev/mapper/lvm
```
Create the volume group named MyStorage, adding the previously created
physical volume to it:
```
 vgcreate MyStorage /dev/mapper/lvm
```
Create all your logical volumes on the volume group:
```
lvcreate -L 8G MyStorage -n swapvol
lvcreate -l +100%FREE MyStorage -n rootvol
```

Format your filesystems on each logical volume:

```
mkfs.ext4 /dev/mapper/MyStorage-rootvol
mkswap /dev/mapper/MyStorage-swapvol
```
Mount your filesystems:

```
mount /dev/MyStorage/rootvol /mnt
swapon /dev/MyStorage/swapvol
```
For more info, see [here](https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system#Preparing_the_ogical_volumes).

### Preparing the boot partition

The bootloader loads the kernel, `initramfs`, and its own configuration files from the `/boot` directory. This directory must be located on a separate unencrypted filesystem.

Create an `ext2` filesystem on the partition intended for `/boot`. Any filesystem that can be read by the bootloader is eligible.
```
 mkfs.ext2 /dev/sda1
```
Create the directory `/mnt/boot`:
```
 mkdir /mnt/boot
```
Mount the partition to `/mnt/boot`:
```
 mount /dev/sda1 /mnt/boot
```

## Installing the base system

### Get internet
Check if the connection is up:
```
ping -c 3 www.google.com
```
```
PING www.l.google.com (74.125.132.105) 56(84) bytes of data.
64 bytes from wb-in-f105.1e100.net (74.125.132.105): icmp_req=1 ttl=50
time=17.0 ms
64 bytes from wb-in-f105.1e100.net (74.125.132.105): icmp_req=2 ttl=50
time=18.2 ms
64 bytes from wb-in-f105.1e100.net (74.125.132.105): icmp_req=3 ttl=50
time=16.6 ms

--- www.l.google.com ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 16.660/17.320/18.254/0.678 ms
```
If not try 
```
systemctl stop dhcpcd.service
```
```
systemctl start dhcpcd.service
```
I used a wired connection here, but you can setup [wireless easily](https://wiki.archlinux.org/index.php/Beginners%27_guide#Wireless), too.
Make sure to have the [wifi switch of your laptop turned
on](http://forums.lenovo.com/t5/T400-T500-and-newer-T-series/t420s-Wireless-Connection-problem/td-p/752183) (face palm).


### Install 

The base system is installed using the `pacstrap` script. The `-i` switch can be
omitted if you wish to install every package from the base group without
prompting. You may also want to include `base-devel`, as you will need these
packages should you want to build packages from the AUR or using the ABS:
```
pacstrap -i /mnt base base-devel
```

### Configure system

Lets jump into our new system and do some configuration. `Chroot` is a tool
that allows us to change our root system and make changes as if we were
actually running the other device. This is a wonderful tool if you ever break
your system and need to get back in.
```
# arch-chroot /mnt /bin/bash
```

#### Locales

Locales are used by `glibc` and other locale-aware programs or libraries for
rendering text, correctly displaying regional monetary values, time and date
formats, alphabetic idiosyncrasies, and other locale-specific standards.

Edit appropriately for your language.

```
vi /etc/locale.gen
```
Uncomment this line if you want to use English. Only use UTF-8 options.
```
en_US.UTF-8 UTF-8
```
Generate your locale.

```
locale-gen
```
Set the locale environment variables.

```
echo LANG=en_US.UTF-8 > /etc/locale.conf
export LANG=en_US.UTF-8
```

#### Console fonts

Lets set our keymaps and fonts. The default keymap is "us", only needs to be
adjusted if “us” does not apply to you. I love Terminus for its legibility as a
mono-spaced font. I will be setting the environment variable here.
```
setfont Lat2-Terminus16
```
Create and edit `/etc/vconsole.conf` and add your preferred font.
```
# vi /etc/vconsole.conf
```
I will be adding this line.
```
FONT=Lat2-Terminus16
```

#### Time zones

Find where you are in the world; drill down until you find the location closest to you.
```
# ls /usr/share/zoneinfo/
```
Link your timezone to `localtime`
```
# ln -s /usr/share/zoneinfo/US/Pacific /etc/localtime
```

#### Hardware Clock

We want our clock to stay synced up with the rest of the world. It is
especially important you have an accurate clock if you use an authentication
system such as Kerberos. We are eventually going to use ntp for this, but for
now UTC time will be just fine. I noticed that systemd wont let you start the
daemon while we are chrooted so this will have to be done later.
```
hwclock -w -u
```

#### Hostname
```
# echo vesuvius > /etc/hostname
```

### Wireless
```
pacman -S wireless_tools wpa_supplicant wpa_actiond dialog iw
```

### Recreate initial ramdisk
Setting mkinit hooks
```
vi /etc/mkinitcpio.conf
```
where the MODULES- und HOOKS-values  are configured:
```
MODULES="ext4"
HOOKS="base udev autodetect block keyboard keymap encrypt lvm2 resume
filesystems fsck shutdown"
```
uncomment the line
```
COMPRESSION="xz"
```
Then save and update
```
mkinitcpio -p linux
```
For more see
[here](https://wiki.archlinux.org/index.php/Suspend_and_hibernate#Required_kernel_parameters)
and
[here](https://wiki.archlinux.org/index.php/Dm-crypt/Swap_encryption#With_suspend-to-disk_support)

### Bootloader
Install
```
# pacman -S syslinux
# syslinux-install_update -iam
```
Configure
```
vi /boot/syslinux/syslinux.cfg

...
LABEL arch
    MENU LABEL Arch Linux
    LINUX ../vmlinuz-linux
		APPEND cryptdevice=/dev/sda2:MyStorage root=/dev/mapper/MyStorage-rootvol rw resume=/dev/mapper/MyStorage-swapvol
    INITRD ../initramfs-linux-fallback.img
```
Now get the persistent partition UUID from
```
lsblk -f

NAME                         FSTYPE      LABEL  UUID                                 MOUNTPOINT
sda                                                                             
├─sda1                       ext2               CBB6-24F2                            /boot
├─sda2                       crypto_LUKS        0a3407de-014b-458b-b5c1-848e92a327a3 
		└─MyStorage ...
		    └─MyStorage-swapvol ....
		    └─MyStorage-rootvol ....
```
and change the name of the volume `cryptdevice=/dev/sda2:MyStorage` to the
persistent UUID 
```
cryptdevice=UUID="0a3407de-014b-458b-b5c1-848e92a327a3":MyStorage root=/dev/mapper/MyStorage-rootvol rw resume=/dev/mapper/MyStorage-swapvol
```
This is recommended. If your machine has more than one SATA, SCSI or IDE
disk controller, the order in which their corresponding device nodes are
added is arbitrary. This may result in device names like /dev/sda and
/dev/sdb switching around on each boot, culminating in an unbootable system,
kernel panic, or a block device disappearing. [Persistent naming solves these
issues.](https://wiki.archlinux.org/index.php/Persistent_block_device_naming)

### Set root password
```
passwd
```

### User and groups

We don’t use root for anything but system maintenance, so we need a daily
user. It helps to know what the user is going to be used for so you can
assign it to the relevant groups. A good admin needs to have an
understanding of user and group concepts, I encourage you to [read up on
it](https://wiki.archlinux.org/index.php/Users_and_Groups)
```
# useradd -m -g users -G audio,disk,storage,video,wheel -s /bin/bash tony
# passwd tony
```
Since we added our user to the group ‘wheel’ we also need the `sudo`
package. Sudo makes administration much easier so lets pull it in.

```
# pacman -S sudo
```

use visudo

```
visudo
```
and uncomment the appropriate line to allow members of wheel to act as root
```
%wheel ALL=(ALL) ALL
```

This functionality can also be obtained by adding a user to `visudo`. Wheel is
nice however, as we may have more admins someday.

### Set up wireless
Run
```
wifi-menu
```
get your wireless interface name
```
ip link
```
Your wireless will typically be something like `wlp3s0`.
Enable the `netctl-auto` service, which will connect to known networks and
gracefully handle roaming and disconnects:
```
# systemctl enable netctl-auto@interface_name.service
```

### Umount and reboot

The step you’ve been waiting for, let’s get out of chroot, unmount and
reboot!

```
exit
umount /mnt/home
umount /mnt/
reboot
```

First Light
-----------
Now after the reboot login in with your normal user name and become
superuser.  
```
su
```

### Set up package manager
```
vi /etc/pacman.conf
```

If you're on a 64-bit machine, you should enable the `[multilib]` repository,
which lets you install both 64- and 32-bit programs. To do so, add the
following lines to the bottom of the config file:

```
[multilib]
Include = /etc/pacman.d/mirrorlist
```
Otherwise leave it as is. Now update pacman
```
pacman -Sy
```

### Network Time Protocol

Arch synced up with a time-server so we don’t have to worry about clock
skew, which can really mess with certain pieces of software.
```
pacman -S ntp
```
Edit `/etc/ntp.conf` with your NTP servers. You can find a server near you
here: http://www.pool.ntp.org/zone 
```
vi /etc/ntp.conf
```
change to

```
server 0.us.pool.ntp.org iburst
server 1.us.pool.ntp.org iburst
server 2.us.pool.ntp.org iburst
server 3.us.pool.ntp.org iburst
```
or
```
server 0.de.pool.ntp.org
server 1.de.pool.ntp.org
server 2.de.pool.ntp.org
server 3.de.pool.ntp.org
```
what ever is closest to you.

Start ntpd

```
# systemctl start ntpd
```

Enable ntpd to start at boot

```
# systemctl enable ntpd
```

Typing `date` at this point should show the correct date and time.

### Git
```
pacman -S git
```

Customize your arch
-------------------
First, become a normal user again.
Pull in 
```
mkdir github
cd github/
git clone https://github.com/frankMilde/install-arch-linux-system.git
cd install-arch-linux-system
./install-arch-packages.sh
./install-suckless-software.sh
cd
git clone https://github.com/frankMilde/dot-files.git
cd dot-files/
stow stow
stow bash
stow fonts
stow mc
stow vim
stow x
```
maybe you have to delete `.bashrc` and `bash_profile` first.

Now reboot and see if `dwm` is coming up nicely.

### Customize vim 
```
 curl https://raw.githubusercontent.com/Shougo/neobundle.vim/master/bin/install.sh | sh
```
Then open `vim` and type `:NeoBundleInstall`

### Power management 
TODO:

http://forums.linuxmint.com/viewtopic.php?f=49&t=160379
https://wiki.archlinux.org/index.php/Power_management
https://wiki.archlinux.org/index.php/General_recommendations#Power_management
https://wiki.archlinux.org/index.php/Laptop#Power_management
https://wiki.archlinux.org/index.php/Hdparm#Power_management_configuration
https://wiki.archlinux.org/index.php/Power_saving

### Printer CUPS Lexmark

Follow the wiki [here](https://wiki.archlinux.org/index.php/Lexmark) and
[here](https://wiki.archlinux.de/title/Drucker):

Install 
```
cups
libcups
glibc
ncurses
libusb
libxext
libxtst
libxi
libstdc++5
heimdal
```

Download Lexmarks CUPS ppd files and install via provided `install` sh
script.

Create printer user group and add yourself
```
sudo groupadd printadmin 
sudo gpasswd -a username printadmin       # for printer administration
sudo gpasswd -a username lp               # for printing priviledges
```
Then edit `/etc/cups/cups-files.conf` and add:
```
SystemGroup sys root printadmin
```
Finally restart `org.cups.cupsd.service`. The user must re-login for these
changes to take effect. 
```
sudo systemctl restart org.cups.cupsd.service
```
Then add printer via CUPS web interface by loading in firefox
```
http://localhost:631/
```

restart CUPS 

