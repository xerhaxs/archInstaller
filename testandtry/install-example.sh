#!/bin/sh

loadkeys de

# formatting disk
lsblk
echo "Wo soll Arch installiert werden?"
read disklocation
gdisk $disklocation

lsblk
echo "Welche Partion soll verschlüsselt werden?"
read encryptedpart

# crypt lvm setup
modprobe dm-crypt

cryptsetup -c aes-xts-plain -y -s 512 luksFormat $encryptedpart

cryptsetup luksOpen $encryptedpart lvm # – Den Container nach /dev/mapper/lvm mappen
pvcreate /dev/mapper/lvm # – PV erstellen
vgcreate main /dev/mapper/lvm # – VG anzulegen
lvcreate -L 10GB -n swap main # – LV für /swap
lvcreate -L 100GB -n root main # – LV für / definieren
lvcreate -l 100%FREE -n home main # – LV für /home erstellen (kleines L im Parameter beachten!)

lsblk
echo "Welche Partion soll die Boot-Partion werden?"
read bootpart

mkfs.fat -F 32 -n UEFI $bootpart # – Formatieren der EFI-Partition
mkswap -L swap /dev/mapper/main-swap # – Das zukünfitge /swap formatieren
mkfs.ext4 -L root /dev/mapper/main-root # – Das zukünftige / formatieren
mkfs.ext4 -L home /dev/mapper/main-home # – Das zukünftige /home formatieren

# Swap aktivieren
swapon /dev/mapper/main-swap

# Rootpartition mounten
mount /dev/mapper/main-root /mnt

# Homepartition mounten
mkdir /mnt/home
mount /dev/mapper/main-home /mnt/home

# Bootpartition mounten
mkdir /mnt/boot
mount $bootpart /mnt/boot


# arch-user-laptop-conf.sh for new system
mkdir /mnt/etc/recoveryfiles/
cp -r /usr/local/bin/Data/ /mnt/etc/recoveryfiles/
cp -r /usr/local/bin/arch-user-laptop-conf.sh /mnt/bin/
cp -r /usr/local/bin/arch-install-laptop-conf.sh /mnt/bin/
chmod -R u+x /mnt/bin/arch-user-laptop-conf.sh
chmod -R u+x /mnt/bin/arch-install-laptop-conf.sh

# arch-chroot
arch-chroot /mnt

echo "Fertig mit Basisinstallation. Weiter mit arch-user-laptop-conf.sh..."
