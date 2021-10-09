#! /usr/bin/env bash

# disk='sda'
# disk='vda'
disk='nvme'

user='trac'
usergroup='wheel,rfkill,video'
usersh='/bin/zsh'

hostname='tracsys'
timezone='Africa/Dakar'
lang='fr_FR.UTF-8'
keymap='fr-latin9'
font='Lat2-Terminus16'
grubtimeout='0'
grubtarget='x86_64-efi'
efidirectory='/efi'
bootloaderid='ARCH_GRUB'

case "$disk" in
   'nvme')
      swap_partition='/dev\/nvme0n1p2'
      ;;
   'sda')
      swap_partition='/dev\/sda2'
      ;;
   'vda')
      swap_partition='/dev\/vda2'
      ;;
esac

if [ ! $(echo "$USER") = 'root' ];then
   echo -e '\n\t You must be root for execute this script\n'
   exit 1
fi

echo -e '\n\t Install essential package\n'
pacman --noconfirm -S linux-zen linux-zen-headers linux-firmware
pacman --noconfirm -S mtools dosfstools lsb-release ntfs-3g exfat-utils
pacman --noconfirm -S networkmanager bluez
pacman --noconfirm -S vim
pacman --noconfirm -S man-db man-pages texinfo
pacman --noconfirm -S base-devel git
pacman --noconfirm -S bash-completion zsh zsh-completions

echo -e '\n\t Configure the system\n'

echo -e '\n\t Time zone\n'
ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime
hwclock --systohc

echo -e '\n\t Localization\n'
sed -i "s/#$lang/$lang/" /etc/locale.gen
locale-gen
echo "LANG=$lang" > /etc/locale.conf
echo 'LC_COLLATE=C' >> /etc/locale.conf
echo "KEYMAP=$keymap" > /etc/vconsole.conf
echo "FONT=$font" >> /etc/vconsole.conf
export "LANG=$lang"

echo -e '\n\t Network configuration\n'
echo "$hostname" > /etc/hostname
echo '127.0.0.1    localhost' >> /etc/hosts
echo '::1          localhost' >> /etc/hosts
echo "127.0.0.1    $hostname" >> /etc/hosts

echo -e '\n\t Grub\n'
pacman -S grub efibootmgr
sed -i "s/GRUB_TIMEOUT=5/GRUB_TIMEOUT=$grubtimeout/" /etc/default/grub
sed -i "s/quiet/quiet\ resume=\\$swap_partition\ ipv6.disable=1/" /etc/default/grub
grub-install --target="$grubtarget" --efi-directory="$efidirectory" --bootloader-id="$bootloaderid" --recheck
grub-mkconfig -o /boot/grub/grub.cfg

echo -e '\n\t Mkinitcpio\n'
sed -i 's/HOOKS=(base\ udev\ autodetect\ modconf\ block\ filesystems\ keyboard\ fsck)/HOOKS=(base\ udev\ resume\ autodetect\ modconf\ block\ filesystems\ keyboard\ fsck)/' /etc/mkinitcpio.conf
mkinitcpio -p linux-zen

echo -e '\n\t Other stuff\n'
echo 'vm.swappiness=10' > /etc/sysctl.d/99-sysctl.conf
echo 'blacklist pcspkr' > /etc/modprobe.d/nobeep.conf
echo 'blacklist iTCO_wdt' > /etc/modprobe.d/nowatchdog.conf

echo -e '\n\t Services\n'
systemctl enable NetworkManager
systemctl enable bluetooth

echo -e '\n\t User password\n'
useradd -m -G "$usergroup" -s "$usersh" "$user"
passwd "$user"

echo -e '\n\t Root password\n'
passwd

echo -e '\n\t Execute rm archchroot_install.sh && exit'
echo -e '\n\t Execute umount -R /mnt && reboot\n'
