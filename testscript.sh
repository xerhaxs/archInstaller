#!/bin/bash

CHOSEN_DRIVE=/dev/vda

	## Load encryptin tools
	modprobe dm-crypt
	
	## Create GPT partition type
	parted $CHOSEN_DRIVE mklabel gpt

	## Create Crypt + Boot partition
	parted $CHOSEN_DRIVE mkpart primary fat32 1MiB 513MiB
	parted $CHOSEN_DRIVE set 1 esp on
	parted $CHOSEN_DRIVE --script mkpart primary ext4 513MiB 100%

	# Init boot + crypt drive
	if [[ $CHOSEN_DRIVE == *"nvme"* ]]; then 
			BOOT_DRIVE=$CHOSEN_DRIVE"p1"
			CRYPT_DRIVE=$CHOSEN_DRIVE"p2"
		else
			BOOT_DRIVE=$CHOSEN_DRIVE"1"
			CRYPT_DRIVE=$CHOSEN_DRIVE"2"
	fi
	
	# Encrypt second partition
	cryptsetup --cipher aes-xts-plain64 --key-size 512 --hash sha512 luksFormat $CRYPT_DRIVE --label CRYPTDRIVE

	# Open encrypted partition
	cryptsetup luksOpen $CRYPT_DRIVE lvm

	# Create root + home volume
	pvcreate /dev/mapper/lvm
	vgcreate crypt /dev/mapper/lvm
	lvcreate -l 40%FREE -n root crypt
	lvcreate -l 100%FREE -n home crypt

	# Init crypt root and crypt home
	CRYPT_ROOT_DRIVE="/dev/mapper/crypt-root"
	CRYPT_HOME_DRIVE="/dev/mapper/crypt-home"

	# Create file system
	mkfs.fat -F 32 -n UEFI $BOOT_DRIVE
	mkfs.ext4 -L root $CRYPT_ROOT_DRIVE
	mkfs.ext4 -L home $CRYPT_HOME_DRIVE

	# Mount the file system
	mount $CRYPT_ROOT_DRIVE /mnt/
	mkdir /mnt/boot
	mount $BOOT_DRIVE /mnt/boot
	mkdir /mnt/home
	mount $CRYPT_HOME_DRIVE /mnt/home
