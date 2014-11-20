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
$ df -B1 /dev/sdd3
>  Filesystem        1B-blocks         Used   Available Use% Mounted on
>  /dev/sdd3      488185536512 382407708672 80955781120  83% /home

$ DISK_SIZE=$(df -B1 /dev/<drive> | tail -n1 | tr -s ' ' | cut -d' ' -f2)
$ PHYS_BLOCK_SIZE=$(cat /sys/block/<drive>/queue/physical_block_size)
$ NUM_BLOCKS=$((DISK_SIZE / PHYS_BLOCK_SIZE))

$ openssl enc -aes-256-ctr -pass pass:"$(dd if=/dev/random bs=128 count=1 2>/dev/null | base64)" -nosalt </dev/zero \
    | pv -bartpes $DISK_SIZE | dd bs=$PHYS_BLOCK_SIZE count=$NUM_BLOCKS of=/dev/<drive>
```
The above command creates a 128 byte encryption key seeded from
`/dev/urandom`.  `AES-256` in `CTR mode` is used to encrypt `/dev/zero`'s
output with the `urandom` key. Utilizing the cipher instead of a
pseudorandom source results in very high write speeds and the result is a
device filled with AES ciphertext. 

### Create new harddrive partitions

To achieve our setup we need two partitions, one for `/boot` as it cannot be
encrypted, and second one that will host the encrypted `LUKS` partition under
which the LVMs run. This setup is called **LVM on LUKS** as first everything
is encrypted and then under the encryption the logical volumes created.
We use [fdisk](http://tldp.org/HOWTO/Partition/fdisk_partitioning.html)
([more info on fdisk usage](https://wiki.archlinux.org/index.php/Beginners%27_guide/Preparation#Using_fdisk_to_create_MBR_partitions))
as our tool of choice:
```
$ fdisk /dev/hdb
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
Last sector, +sectors or +size{K,M,G,T,P} (31459328-209715199....., default 209715199):: +256M
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
Last sector, +sectors or +size{K,M,G,T,P} (31459328-209715199....., default 209715199)::<RETURN>
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
[options](https://wiki.archlinux.org/index.php/Dm-crypt/Device_encryption#Encryption
options for LUKS mode).
```
cryptsetup -v --cipher serpent-xts-plain64 --key-size 512 --hash sha512 --iter-time 5000 --use-random luksFormat /dev/sda2
```
