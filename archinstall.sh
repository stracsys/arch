#! /usr/bin/env bash

# disk='sda'
# disk='vda'
disk='nvme'
efidirectory='/mnt/efi'

case "$disk" in
   'nvme')
      efi_partition='/dev/nvme0n1p1'
      swap_partition='/dev/nvme0n1p2'
      root_partition='/dev/nvme0n1p3'
      home_partition='/dev/nvme0n1p4'
      ;;
   'sda')
      efi_partition='/dev/sda1'
      swap_partition='/dev/sda2'
      root_partition='/dev/sda3'
      home_partition='/dev/sda4'
      ;;
   'vda')
      efi_partition='/dev/vda1'
      swap_partition='/dev/vda2'
      root_partition='/dev/vda3'
      home_partition='/dev/vda4'
      ;;
esac

if [ ! $(echo "$USER") = 'root' ];then
   echo -e '\n\t You must be root for execute this script\n'
   exit 1
fi

if [ ! -e "$efi_partition" ] ||
   [ ! -e "$swap_partition" ] ||
   [ ! -e "$root_partition" ] ||
   [ ! -e "$home_partition" ]
then 
   echo -e '\n\t Execute this script after partitionning the disk\n'
   exit 1
fi

echo -e '\n\t Mirrorlist setup\n'
pacman --noconfirm -S pacman-contrib
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
rankmirrors -n 10 /etc/pacman.d/mirrorlist.bak > /etc/pacman.d/mirrorlist

echo -e '\n\t Format the partitions\n'
mkfs.fat -F 32 "$efi_partition"
mkswap "$swap_partition"
mkfs.ext4 "$root_partition"
mkfs.ext4 "$home_partition"

echo -e '\n\t Mount the file systems\n'
mount -t ext4 "$root_partition" /mnt
mkdir /mnt/home
mkdir "$efidirectory"
mount -t ext4 "$home_partition" /mnt/home
mount -t vfat "$efi_partition" "$efidirectory"
swapon "$swap_partition"

echo -e '\n\t Install base package\n'
pacstrap /mnt base

echo -e '\n\t Generate fstab\n'
genfstab -U -p /mnt >> /mnt/etc/fstab

echo -e '\n\t Copy archcroot_install and chroot to /mnt'
echo -e '\t Execute archcroot_install script to continue installation\n'
cp archchroot_install.sh /mnt/root
arch-chroot /mnt

