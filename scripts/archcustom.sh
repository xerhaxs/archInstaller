#!/bin/bash

## This is an installation script for a custom Arch Linux. It is modified for my personal needs. Feel free to use or customize!



###
### ---- Start: Define functions for this installation script ----
###



## Function for sartup message
function_startup_message() {
	whiptail --title "Start installation" --msgbox "This script will guide you through the installation of Arch Linux with customized settings.	Notice, that this script will only work on Arch Linux (and maybe arch-based systems)." 32 128 3>&1 1>&2 2>&3
}

## Function to start the installation guide
function_start_installation_guide() {
	whiptail --title "Start installation guide" --yesno "Do you want to start the installation guide?" 32 128 3>&1 1>&2 2>&3
	if [[ $? -eq 0 ]]; then

		## Detect if the script is compatible with the operation system / host system
		case "$OSTYPE" in
				linux*)
					if grep -q 'Arch Linux' /etc/os-release; then
						echo 'Supported system detected. Continue installation...'
						function_installation_guide
					fi
			;;

			## If an unsupported system gets detected.
			*)
				whiptail --title "ERROR - Unsupported system detected!" --yesno "Your system is not officially supported by this script. It is not recommended to run this script on not officially supported systems, as it can cause damage to your installed systems or it might not work properly. If you decide to run this script anyway - you have been warned! Do you want to continue?" 32 128 3>&1 1>&2 2>&3
				if [[ $? -eq 0 ]]; then
						pacman -Syyu hwinfo git wget
						function_installation_guide
					elif [[ $? -eq 1 ]]; then
						whiptail --title "MESSAGE" --msgbox "Cancelling Process since user pressed <NO>." 32 128 3>&1 1>&2 2>&3
					elif [[ $? -eq 255 ]]; then
						whiptail --title "MESSAGE" --msgbox "User pressed ESC. Exiting the script" 32 128 3>&1 1>&2 2>&3
				fi
			;;
		esac

		elif [[ $? -eq 1 ]]; then
			whiptail --title "MESSAGE" --msgbox "Cancelling Process since user pressed <NO>." 32 128 3>&1 1>&2 2>&3
		elif [[ $? -eq 255 ]]; then
			whiptail --title "MESSAGE" --msgbox "User pressed ESC. Exiting the script" 32 128 3>&1 1>&2 2>&3
	fi
}

## Function to set the keyboard layout during the installation process
function_kbd_load() {
	KBD_OPTIONS=()

	while IFS= read -r KBD_LINE; do
		KBD_OPTIONS+=("$KBD_LINE" "")
	done < <(localectl list-keymaps)

	CHOSEN_KBD_LAYOUT=$(whiptail --title "Keyboard Layout" --menu "Pick your keyboard layout (This keyboard layout will only be used during the installation process.)" 32 128 16 "${KBD_OPTIONS[@]}" 3>&1 1>&2 2>&3)
	loadkeys $CHOSEN_KBD_LAYOUT
}

## Function to detect and set a password
function_password() {
	function_set_password() {
		PASSWORD=$(whiptail --title "Set password" --passwordbox "Chose a strong password." 32 128 3>&1 1>&2 2>&3)

		PASSWORD_CHECK=$(whiptail --title "Confirm password" --passwordbox "Type your password again to confirm." 32 128 3>&1 1>&2 2>&3)
	}

	function_set_password
	PASSWORD_SET=false

	while [ $PASSWORD_SET = false ]; do
		if [ $PASSWORD == $PASSWORD_CHECK ]; then
			PASSWORD_SET=true
			echo "$PASSWORD"
		else
			whiptail --title "Incorrect Password" --msgbox "The passwords do not match. Please try again." 32 128 3>&1 1>&2 2>&3
			function_set_password
		fi
	done
}

## Fubction to detect CPU Microcode
function_detect_microcode() {
	if lscpu | grep "AMD"; then
			echo "Add amd-ucode to installation query, because AMD CPU has been found..."
			CPU_MICROCODE="amd-ucode"
		elif lscpu | grep "Intel"; then
			echo "Add intel-ucode to installation query, because Intel CPU has been found..."
			CPU_MICROCODE="intel-ucode"
		else
			whiptail --title "Hardware Configuration" --msgbox "Unknown CPU-Architektur detected. Continue installation without Microcode." 32 128 3>&1 1>&2 2>&3
			CPU_MICROCODE="amd-ucode intel-ucode"
	fi
}

## Function to detect GPU driver
function_detect_gpu() {
	if lshw -C display | grep "AMD"; then
			echo "Add AMD-driver to installation query, because AMD GPU has been found..."
			GPU_DRIVER="pkgLists/driverLists/amdGpuPkgs.txt"
			MODULES_DRIVER="sed -i 's/MODULES=(ext4)/MODULES=(ext4 amdgpu)/g' /etc/mkinitcpio.conf"
		elif lshw -C display | grep "NVIDIA"; then
				CHOSEN_NVIDIA_DRIVER=$(whiptail --title "Nvidia driver selection" --menu "Do you want to use proprietary or open-source drivers for your Nvidia card?" 32 128 2 \
				"Proprietary" "Much better performance" \
				"Open-Source" "Free and open-source" 3>&1 1>&2 2>&3)

				echo $CHOSEN_NVIDIA_DRIVER

			if [ $CHOSEN_NVIDIA_DRIVER == "Proprietary" ]; then
					echo "Add proprietary nvidia driver to installation query..."
					GPU_DRIVER="pkgLists/driverLists/nvidiaClosedGpuPkgs.txt"
					MODULES_DRIVER="sed -i 's/MODULES=(ext4)/MODULES=(ext4 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/g' /etc/mkinitcpio.conf"
				else
					echo "Add open-source nvidia driver to installation query..."
					GPU_DRIVER="pkgLists/driverLists/nvidiaOpenGpuPkgs.txt"
					MODULES_DRIVER="sed -i 's/MODULES=(ext4)/MODULES=(ext4 nouveau)/g' /etc/mkinitcpio.conf"
			fi

		else
			whiptail --title "Hardware Configuration" --msgbox "Unknown GPU detected. Continue installation without GPU-Drivers" 32 128 3>&1 1>&2 2>&3
	fi
}

## Kernel and system configuration
function_select_system_type() {
	CHOSEN_SYSTEM_TYPE=$(whiptail --title "Kernel and System configuration" --menu "Which Kernel option do you prefer?" 32 128 4 \
	"Basic" 	"Everything will be installed on one partition. No security modules or special modifications. Normal Kernel." \
	"Zen" 		"Everything will be installed on one partition. The Zen-Kernel will be used. Some tweaks for better performence will be made." \
	"LTS"		"Everything will be installed on one partition. The LTS-Kernel will be used." \
	"Hardened"	"The system will be a Fort Nox for your data. The system will be installed with SeLinux, Full Diks Encryption etc." 3>&1 1>&2 2>&3)
}

## Function to set installation disk
function_select_installation_disk() {
	DISKS=$(lsblk | grep disk | awk '{print $1}')

	DISK_OPTIONS=()
	for DISK in $DISKS; do
		DISK_SIZE=$(lsblk "/dev/$DISK" | grep disk | awk '{print $4}')
		DISK_OPTIONS+=("/dev/$DISK" "$DISK_SIZE")
	done

	CHOSEN_DRIVE=$(whiptail --title "Menu selected Drive" --menu "Where should Arch Linux be installed?" 32 128 16 "${DISK_OPTIONS[@]}" 3>&1 1>&2 2>&3)

	echo "$CHOSEN_DRIVE"
}

## Standard partition layout
function_partition_basic() {
	parted $CHOSEN_DRIVE mklabel gpt
	parted $CHOSEN_DRIVE mkpart primary fat32 1MiB 513MiB
	parted $CHOSEN_DRIVE set 1 esp on
	parted $CHOSEN_DRIVE mkpart primary ext4 513MiB 100%

	BOOT_DRIVE=$CHOSEN_DRIVE"1"
	SYSTEM_DRIVE=$CHOSEN_DRIVE"2"

	mkfs.fat -F 32 -n UEFI $BOOT_DRIVE
	mkfs.ext4 -L system -n 32k $SYSTEM_DRIVE

	mount $SYSTEM_DRIVE /mnt
	mkdir /mnt/boot
	mount $BOOT_DRIVE /mnt/boot

	## Create Swap file
	dd if=/dev/zero of=/mnt/swapfile bs=1M count=16k status=progress
	chmod 0600 /mnt/swapfile
	mkswap -U clear /mnt/swapfile
	swapon /mnt/swapfile

	# Generate fstab
	genfstab -Lp /mnt > /mnt/etc/fstab
}

## Hardened partition layout
function_partition_hardened() {
	

	## Load encryptin tools
	modprobe dm-crypt
	
	## Create GPT partition type
	parted $CHOSEN_DRIVE mklabel gpt

	## Create EFI partition
	parted $CHOSEN_DRIVE mkpart primary fat32 1MiB 513MiB
	parted $CHOSEN_DRIVE set 1 esp on
	EFI_DRIVE=$CHOSEN_DRIVE"1"

	## Create Root + Boot partition
	parted $CHOSEN_DRIVE --script mkpart primary ext4 513MiB 50%
	CRYPT_ROOT_DRIVE=$CHOSEN_DRIVE"2"
	cryptsetup -c aes-xts-plain -y -s 512 luksFormat --type luks1 $CRYPT_ROOT_DRIVE
	cryptsetup luksOpen $CRYPT_ROOT_DRIVE
	mkfs.ext4 -L /dev/mapper/crypt-root
	mkfs.ext4 -L root 

	## Create Home partition
	parted $CHOSEN_DRIVE mkpart primary 50% 100%
	CRYPT_HOME_DRIVE=$CHOSEN_DRIVE"3"
	cryptsetup -c aes-xts-plain -y -s 512 luksFormat --type luks1 $CRYPT_HOME_DRIVE
	cryptsetup luksOpen $CRYPT_HOME_DRIVE
	mkfs.ext4 -L /dev/mapper/crypt-home
	mkfs.ext4 -L home

	# Mount the file system
	mount $CRYPT_ROOT_DRIVE /mnt/
	mkdir /mnt/efi/
	mount $EFI_DRIVE /mnt/efi
	mkdir /mnt/home
	mount $CRYPT_HOME_DRIVE /mnt/home

	## Create Swap file
	dd if=/dev/zero of=/mnt/swapfile bs=1M count=16k status=progress
	chmod 0600 /mnt/swapfile
	mkswap -U clear /mnt/swapfile
	swapon /mnt/swapfile
	
	# Generate fstab
	genfstab -Lp /mnt > /mnt/etc/fstab
}

## Function to set the hostname
function_select_hostname() {
	HOSTNAME=$(whiptail --title "Set Hostname" --inputbox "Chose the Hostname of the computer." 32 128 3>&1 1>&2 2>&3)
	echo "Hostname: $HOSTNAME"
}

## Function to set the Timzone for the installation system
function_select_timezone() {
	# Get list of timezones
	TIMEZONELIST=$(timedatectl list-timezones)
	# Show radiolist

	TIMEZONE=$(whiptail --title "Timezone" --radiolist \
	"Choose your timezone:" 32 128 16 \
	$(for TZ in $TIMEZONELIST; do \
		echo $TZ \"\" off; \
	done) 3>&1 1>&2 2>&3)
}

## Function to set the locales
function_system_local() {
	# File path to the locale file
	LOCALE_FILE="/etc/locale.gen"

	# to beginning of lines that don't start with #
	sed -i '/^[^#]/ s/^/#/' "$LOCALE_FILE"

	# Read the file and generate an array of locales
	IFS=$'\n' LOCALES=($(tail -n +18 "$LOCALE_FILE" | sed '/^$/d')) # Ignore the first 17 lines and empty lines
	OPTIONS=() # Initialize an array to store the dialog options
	for LOCALE in "${LOCALES[@]}"; do
	if [[ "$LOCALE" =~ ^#.*$ ]]; then
		OPTIONS+=("$LOCALE" "" Off)
	else
		OPTIONS+=("$LOCALE" "" On)
	fi
	done

	# Generate the whiptail menu and save the results as an array
	SELECTED_LOCALE=$(whiptail --title "Select Locale" --radiolist "Choose your locale:" 20 78 10 "${OPTIONS[@]}" 3>&1 1>&2 2>&3)

	echo "Locale set to $SELECTED_LOCALE"
}

## Function to set the system keyboard layout
function_system_keyboard_layout() {
	# Set the variables
	LAYOUT_LANG_LIST=( $(localectl list-keymaps | sort) )
	LAYOUT_MENU_LIST=()

	# Iterate through the list of available language and create the menu
	for LAYOUT_LANG in "${LAYOUT_LANG_LIST[@]}"; do
		LAYOUT_MENU_LIST+=("$LAYOUT_LANG" "" off)
	done

	# Show the Whiptail menu and set the keyboard layout
	CHOSEN_SYSTEM_KEYBOARD_LAYOUT=$(whiptail --title "Select Keyboard Layout" --radiolist "Chose your keyboard layout:" 32 128 16 "${LAYOUT_MENU_LIST[@]}" 3>&1 1>&2 2>&3)
}

## Function to set the root credentials
function_select_root_credentials() {
	ROOTPASS=$(function_password)
}

## Function to set the user credentials
function_select_user_credentials() {
	CHROOTUSERNAME=$(whiptail --title "Create User" --inputbox "Chose your username (only lowercase letters, numbers and no spaces or special characters)" 32 128 3>&1 1>&2 2>&3)
	USERPASS=$(function_password)
}



###
### ---- End: Define functions for this installation script ----
###

###
### ---- Start: Configuration of the system ----
###



function_startup_message

## Installation guide
function_installation_guide() {
	function_kbd_load

	function_select_installation_disk

	function_detect_microcode

	function_detect_gpu

	function_select_system_type


	## Test for UEFI
	#ls /sys/firmware/efi/efivars

	## Secure erasure of the drive
	#dd if=$CHOSEN_DRIVE of=/dev/zero status=progress

	function_select_hostname

	## Define timezone
	function_select_timezone

	## Locals
	function_system_local

	## Keyboard Layout
	function_system_keyboard_layout

	### User Configuration

	function_select_root_credentials

	function_select_user_credentials


###
### ---- End: Configuration of the system ----
###



	## Last confirmation before executing script to install everything
	whiptail --title "Finish and execute" --yesno "The configuration is complete. Do you want to run and execute your configuration? (This can take up some time.)" 32 128 3>&1 1>&2 2>&3

	if [[ $? -eq 0 ]]; then
			whiptail --title "Final Information" --msgbox "When the process is done, the computer should reboot automatically. Please do not power off or disconnect your computer from the network during the process." 32 128 3>&1 1>&2 2>&3
			


			###
			### ---- Start: Executing of the installation ----
			###



			### Hardware Configuration
			## Install core packages
			if [ $CHOSEN_SYSTEM_TYPE == "Basic" ]; then
					function_partition_basic
					pacstrap /mnt - < pkgLists/systemLists/linuxPkgs.txt
					pacstrap /mnt - < pkgLists/systemLists/corePkgs.txt

					MKINIT_KERNEL="mkinitcpio -p linux"

					# Update mkinitcpio.conf
					sed -i '/^HOOKS=/c\HOOKS=(base systemd autodetect modconf kms keyboard keymap plymouth sd-vconsole block filesystems fsck resume shutdown)' 

					MKINIT_KERNEL="mkinitcpio -p linux"

					arch-chroot /mnt/ grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck --debug

					arch-chroot /mnt/ grub-mkconfig -o /boot/grub/grub.cfg

				elif [ $CHOSEN_SYSTEM_TYPE == "Zen" ]; then
					function_partition_basic
					pacstrap /mnt - < pkgLists/systemLists/linux-ltsPkgs.txt
					pacstrap /mnt - < pkgLists/systemLists/corePkgs.txt

					MKINIT_KERNEL="mkinitcpio -p linux-lts"
					
					# Update mkinitcpio.conf
					sed -i '/^HOOKS=/c\HOOKS=(base systemd autodetect modconf kms keyboard keymap plymouth sd-vconsole block filesystems fsck resume shutdown)' 

					MKINIT_KERNEL="mkinitcpio -p linux-lts"

					arch-chroot /mnt/ grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck --debug

					arch-chroot /mnt/ grub-mkconfig -o /boot/grub/grub.cfg

				elif [ $CHOSEN_SYSTEM_TYPE == "LTS" ]; then
					function_partition_basic
					pacstrap /mnt - < pkgLists/systemLists/linux-zenPkgs.txt
					pacstrap /mnt - < pkgLists/systemLists/corePkgs.txt

					MKINIT_KERNEL="mkinitcpio -p linux-zen"

					# Update mkinitcpio.conf
					sed -i '/^HOOKS=/c\HOOKS=(base systemd autodetect modconf kms keyboard keymap plymouth sd-vconsole block filesystems fsck resume shutdown)' 

					MKINIT_KERNEL="mkinitcpio -p linux-zen"

					arch-chroot /mnt/ grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck --debug

					arch-chroot /mnt/ grub-mkconfig -o /boot/grub/grub.cfg

				elif [ $CHOSEN_SYSTEM_TYPE == "Hardened" ]; then
					function_partition_hardened
					pacstrap /mnt - < pkgLists/systemLists/linux-hardenedPkgs.txt
					pacstrap /mnt - < pkgLists/systemLists/corePkgs.txt 

					MKINIT_KERNEL="mkinitcpio -p linux-hardened"

					# Update mkinitcpio.conf
					sed -i '/^HOOKS=/c\HOOKS=(base systemd autodetect modconf kms keyboard keymap plymouth sd-vconsole block sd-encrypt lvm2 filesystems fsck resume shutdown)' 

					MKINIT_KERNEL="mkinitcpio -p linux-hardened"

					arch-chroot /mnt/ grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB --recheck --debug

					arch-chroot /mnt/ grub-mkconfig -o /boot/grub/grub.cfg

					echo "GRUB_ENABLE_CRYPTODISK=y" >> /mnt/etc/default/grub

					arch-chroot /mnt/ grub-mkconfig -o /boot/grub/grub.cfg
			fi
			
			### System Configuration

			## Enable sudo without password for user(s) during installation
			arch-chroot /mnt/ EDITOR=vim
			sed -i 's/#%wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /mnt/etc/sudors

			## Set hostname
			echo $HOSTNAME > /mnt/etc/hostname

			## Enable local
			MNT_LOCALE_FILE="/mnt/etc/locale.gen"
			sed -i "/^$SELECTED_LOCALE/s/^#//" "$MNT_LOCALE_FILE"

			## Set language
			echo "LANG=$SELECTED_LOCALE" > /mnt/etc/locale.conf	

			## Set keymap
			arch-chroot /mnt/ localectl set-keymap "$CHOSEN_SYSTEM_KEYBOARD_LAYOUT"
			sed -i "s/KEYMAP=.*/KEYMAP=$CHOSEN_SYSTEM_KEYBOARD_LAYOUT/" /mnt/etc/vconsole.conf
			# Output the selected keyboard layout
			echo "The selected keyboard layout is: $(arch-chroot /mnt/ localectl status | grep "VC Keymap" | awk '{print $3}')"

			## Set timezone
			ln -sf /mnt/usr/share/zoneinfo/$TIMEZONE /mnt/etc/localtime
			arch-chroot /mnt/ timedatectl set-local-rtc 0 # set hardware clock to UTC

			## Generate localisation settings
			arch-chroot /mnt/ locale-gen

			### User Configuration

			## Set Root password
			arch-chroot /mnt/ sudo sh -c "echo root:'$ROOTPASS' | chpasswd"

			## Create User with password
			arch-chroot /mnt/ useradd -m -G users,wheel -s /bin/bash -p $(openssl passwd -1 $USERPASS) $CHROOTUSERNAME

			## Enable multilib
			sed -i '/^#\[multilib]/{n;s/^#//}' /mnt/etc/pacman.conf
			sed -i '/^#\[multilib]/{s/^#//}' /mnt/etc/pacman.conf
			arch-chroot /mnt/ pacman -Syyu --noconfirm

			## Enable chaotic-aur
			#arch-chroot /mnt/ pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com
			#arch-chroot /mnt/ pacman-key --lsign-key FBA220DFC880C036
			#arch-chroot /mnt/ pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
			#echo -e "[chaotic-aur] \nInclude = /etc/pacman.d/chaotic-mirrorlist" | tee -a /mnt/etc/pacman.conf

			## Update mirror lists by speed
			#cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup

			## Install CPU Microcode
			arch-chroot /mnt/ pacman -S --needed --noconfirm $CPU_MICROCODE

			## Install / Set GPU Driver
			arch-chroot /mnt/ pacman -S --needed --noconfirm $GPU_DRIVER
			$MODULES_DRIVER

			## Install Compositor /  Window System
			arch-chroot /mnt/ pacman -S --needed --noconfirm - < pkgLists/systemLists/waylandPkgs.txt
			arch-chroot /mnt/ pacman -S --needed --noconfirm - < pkgLists/systemLists/x11Pkgs.txt
			arch-chroot /mnt/ localectl set-x11-keymap "$CHOSEN_SYSTEM_KEYBOARD_LAYOUT"

			## Setup Firewalld as system wide firewall
			arch-chroot /mnt/ systemctl enable firewalld

			## Enable usefull system daemons
			arch-chroot /mnt/ systemctl enable acpid
			arch-chroot /mnt/ systemctl enable avahi-daemon
			arch-chroot /mnt/ systemctl enable cups.service	
			
			## Change sudo for user(s) to normal
			sed -i 's/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/#%wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /mnt/etc/sudors
			sed -i 's/#%wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' /mnt/etc/sudors

			arch-chroot /mnt/ $MKINIT_KERNEL

			## Reboot system
			whiptail --title "Installation is complete" --yesno "Restart computer?" 32 128 3>&1 1>&2 2>&3

			if [[ $? -eq 0 ]]; then
					umount -a
					systemctl reboot --now
				elif [[ $? -eq 1 ]]; then
					whiptail --title "MESSAGE" --msgbox "Cancelling Process since user pressed <NO>. Returned to shell." 32 128 3>&1 1>&2 2>&3
				elif [[ $? -eq 255 ]]; then
					whiptail --title "MESSAGE" --msgbox "User pressed ESC. Returned to shell." 32 128 3>&1 1>&2 2>&3
			fi



			###
			### ---- End: Executing of the installation ----
			###



		elif [[ $? -eq 1 ]]; then
			whiptail --title "MESSAGE" --msgbox "Cancelling Process since user pressed <NO>." 32 128 3>&1 1>&2 2>&3
		elif [[ $? -eq 255 ]]; then
			whiptail --title "MESSAGE" --msgbox "User pressed ESC. Exiting the script" 32 128 3>&1 1>&2 2>&3
	fi
}

function_start_installation_guide
