#!/bin/bash

## This is an installation script for a custom Arch Linux. It is modified for my personal needs. Feel free to use or customize!



###
### ---- Start: Define functions for this installation script ----
###



## Function to detect and set a password
conf_password() {
	conf_set_password() {
		PASSWORD=$(whiptail --title "Set password" --passwordbox "Choose a strong password." 32 128 3>&1 1>&2 2>&3)
		PASSWORD_CHECK=$(whiptail --title "Confirm password" --passwordbox "Type your password again to confirm." 32 128 3>&1 1>&2 2>&3)
	}
	conf_set_password
	PASSWORD_SET=false
	while [ $PASSWORD_SET = false ]; do
		if [ $PASSWORD == $PASSWORD_CHECK ]; then
			PASSWORD_SET=true
			echo "$PASSWORD"
		else
			whiptail --title "Incorrect Password" --msgbox "The passwords do not match. Please try again." 32 128 3>&1 1>&2 2>&3
			conf_set_password
		fi
	done
}

conf_timeshift_setup() {
	
}


###
### ---- End: Define functions for this installation script ----
###

###
### ---- Start: Configuration of the system ----
###



## Startup massage
whiptail --title "Start installation" --msgbox "This script will guide you through the installation of Arch Linux with customized settings.
Notice, that this script will only work on Arch Linux (and maybe arch-based systems)." 32 128 3>&1 1>&2 2>&3

## Start installation guide
whiptail --title "Start installation guide" --yesno "Do you want to start the installation guide?" 32 128 3>&1 1>&2 2>&3

if [[ $? -eq 0 ]]; then
	## Detect if the script is compatible with the operation system / host system
	case "$OSTYPE" in
			linux*)
			if grep -q 'Arch Linux' /etc/os-release; then
				echo 'Supported system detected. Continue installation...'
				installation_guide
			fi
		;;

		## If an unsupported system gets detected.
		*)
			whiptail --title "ERROR - Unsupported system detected!" --yesno "Your system is not officially supported by this script. It is not recommended to run this script on not officially supported systems, as it can cause damage to your installed systems or it might not work properly. If you decide to run this script anyway - you have been warned! Do you want to continue?" 32 128 3>&1 1>&2 2>&3
			if [[ $? -eq 0 ]]; then
				installation_guide
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

## Installation guide
installation_guide() {
	## Kernel and system configuration
	CHOOSEN_SYSTEM_TYPE=$(whiptail --title "Kernel and System configuration" --menu "Which Kernel option do you prefer?" 32 128 4 \
	"Basic" 	"Everything will be installed on one partition. No security modules or special modifications. Normal Kernel." \
	"Zen" 		"Everything will be installed on one partition. The Zen-Kernel will be used." \
	"LTS"		"Everything will be installed on one partition. The LTS-Kernel will be used." \
	"Hardened"	"The system will be a Fort Nox for your data. The system will be installed with SeLinux, Full Diks Encryption etc." 3>&1 1>&2 2>&3)
	if [ $CHOOSEN_SYSTEM_TYPE == "Basic" ]; then
			KERNEL="linux linux-headers"
			EXECUTING_CMDS+=("" "")
		elif [ $CHOOSEN_SYSTEM_TYPE == "Zen" ]; then
			KERNEL="linux-zen linux-zen-headers"
			EXECUTING_CMDS+=("" "")
		elif [ $CHOOSEN_SYSTEM_TYPE == "LTS" ]; then
			KERNEL="linux-lts linux-lts-headers"
			EXECUTING_CMDS+=("" "")
		elif [ $CHOOSEN_SYSTEM_TYPE == "Hardened" ]; then
			KERNEL="linux-hardened linux-hardened-headers"
			CHOOSEN_INSTALL_LISTS+=()
			EXECUTING_CMDS+=("" "")
		else
			whiptail --title "MESSAGE" --msgbox "User pressed ESC. Exiting the script" 32 128 3>&1 1>&2 2>&3
	fi

	## Drive configuration and disk formatting
	DRIVES=$(lsblk | grep disk)
	echo $DRIVES

	IFS=$(echo -en "\n\b")
	$DRIVES | while IFS= read -r line ; do
		echo "$line"
	done


	lsblk | grep disk | {
	while IFS= read -r ROW; do
			echo "$ROW"
			ROW_COUNT=$((ROW_COUNT+1))
		done
		echo "There were $ROW_COUNT rows."
		echo "$ROW"
	}

	CHOOSEN_DRIVE=$(whiptail --title "Disk for Arch Linux" --menu "Where should Arch Linux be installed?" 32 128 $ROW_COUNT \

	)


	lsblk | grep disk


			dd if=/dev/zero of $DRIVE status==progress
		sgdisk -o
		sgdisk -n 0:0:+512M --t 0:ef00 -c 0:boot $DRIVE
		sgdisk -n 0:0:0 --t 0:8300 -c 0:root $DRIVE









	## Set keymap for installation
	loadkeys de


	## Detect CPU Microcode
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

	## Detect GPU
	if lshw -C display | grep "AMD"; then
			echo "Add AMD-driver to installation query, because AMD GPU has been found..."
			GPU_DRIVER="pkgLists/driverLists/amdGpuPkgs.txt"
			MODULES_DRIVER="sed -i 's/MODULES=(ext4)/MODULES=(ext4 amdgpu)/g' /etc/mkinitcpio.conf"
		elif lshw -C display | grep "NVIDIA"; then
			CHOOSEN_NVIDIA_DRIVER=$(whiptail --title "Nvidia driver selection" --menu "Do you want to use proprietary or open-source drivers for your Nvidia card?" 32 128 2 \
			"Proprietary" "Much better performance" \
			"Open-Source" "Free and open-source" 3>&1 1>&2 2>&3)
			echo $CHOOSEN_NVIDIA_DRIVER
			if [ $CHOOSEN_NVIDIA_DRIVER == "Proprietary" ]; then
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

	## Define hostname
	HOSTNAME=$(whiptail --title "Set Hostname" --inputbox "Choose the Hostname of the computer." 32 128 3>&1 1>&2 2>&3)
	echo "Hostname: $HOSTNAME"

	## Define language (For German: LANG=de_DE.UTF-8)
	#LANG=$()
	LANG="LANG=de_DE.UTF-8"
	echo "System language: $LANG"

	## Define locals (For German:
	# sed -i 's/#de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/g' /etc/locale.gen
	# sed -i 's/#de_DE ISO-8859-1 /de_DE ISO-8859-1 /g' /etc/locale.gen
	# sed -i 's/#de_DE@euro ISO-8859-15 /de_DE@euro ISO-8859-15 /g' /etc/locale.gen)
	LOCALS=$()
	echo "System locals: $LOCALS"

	## Define keymap (For German: KEYMAP=de-latin)
	#KEYMAP=$()
	KEYMAP="KEYMAP=de-latin"

	## Define timezone (For German: ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime)
	#TIMEZONE=$()
	TIMEZONE="/usr/share/zoneinfo/Europe/Berlin"

	### User Configuration

	## Root password
	ROOTPASS=$(conf_password)

	## User creation
	USERNAME=$(whiptail --title "Create User" --inputbox "Choose your username (only lowercase letters, numbers and no spaces or special characters)" 32 128 3>&1 1>&2 2>&3)
	USERPASS=$(conf_password)

	## Choose packages for the system
	whiptail --title "Choosing packages" --yesno "Do you want to install a minimal system without Desktop environment, Window Manager or other non stock programs?" 32 128 3>&1 1>&2 2>&3

	if [[ $? -eq 0 ]]; then

		elif [[ $? -eq 1 ]]; then
			whiptail --title "MESSAGE" --msgbox "Cancelling Process since user pressed <NO>." 32 128 3>&1 1>&2 2>&3
		elif [[ $? -eq 255 ]]; then
			whiptail --title "MESSAGE" --msgbox "User pressed ESC. Exiting the script" 32 128 3>&1 1>&2 2>&3
	fi

	## Configuration of the Desktop environment / Window Manager
	CHOOSEN_USERSPACE=$(whiptail --title "Package Selection" --checklist --separate-output "Which desktop environment or window manager do you want to install?" 32 128 5 \
	'Plasma'		'X11 + Wayland' 	off \
	'Gnome' 		'X11 + Wayland' 	off \
	'XFCE' 			'X11' 				off \
	'Sway' 			'Wayland' 			off \
	'AwesomeWM' 	'X11' 				off \
	3>&1 1>&2 2>&3)
	echo $CHOOSEN_USERSPACE

	## Configuration of Login-Manager
	CHOOSEN_LOGINMANAGER=$(whiptail --title "Package Selection" --radiolist "Which Login-Manager do you want to use?" 32 128 3 \
	'SDDM'		'' 	on 	\
	'GDM' 		'' 	off \
	'LightDM' 	'' 	off \
	3>&1 1>&2 2>&3)
	echo $CHOOSEN_LOGINMANAGER

	## Configuration of user specific packages
	CHOOSEN_USERPACKAGES=$(whiptail --title "Package Selection" --checklist --separate-output "Which desktop environment or window manager do you want to install?" 32 128 12 \
	'Base'				'Browser, Editor, File manager, Calculator etc.' 	on 	\
	'Editing' 			'Photo-, Video-, Audiotools' 						off \
	'Flatpaks'			'Flatpaksupport, Discord, Fluentreader'				off	\
	'Gaming' 			'Steam, Lutris, Heroic'								off \
	'Multimedia' 		'RSS-Client, Videoclient, Mediaplayer' 				off \
	'Office' 			'Mailclient, Office suite, Calendar, Printing'		off \
	'Printing'			'CUPS, Scantools'									off \
	'Privacy'			'Tor, Onineshare, Anonymous Messanger etc.'			off	\
	'Programming' 		'IDEs, Tools, Language support' 					off \
	'Server'			'WebDAV, Nextcloud, PiHole, Jellyfin, Invidious'	off	\
	'Tools'				'Some usefull stuff'								off \
	'VM'				'Virtualisation, QEMU, Libvirt'						off	\
	3>&1 1>&2 2>&3)
	echo $CHOOSEN_USERPACKAGES

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


			### Execute every command to install the operation system

			### Hardware Configuration

			## Install core packages
			pacstrap /mnt - < pkgLists/systemLists/corePkgs.txt

			# Generate fstab
			genfstab -Lp /mnt > /mnt/etc/fstab

			

			### System Configuration

			## Enable sudo without password for user(s) during installation
			arch-chroot /mnt/ EDITOR=vim
			sed -i 's/#%wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /mnt/etc/sudors

			## Set hostname
			echo $HOSTNAME > /mnt/etc/hostname

			## Set language
			echo $LANG > /mnt/etc/locale.conf

			## Set locals
			sed -i 's/#de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/g' /mnt/etc/locale.gen
			sed -i 's/#de_DE ISO-8859-1 /de_DE ISO-8859-1 /g' /mnt/etc/locale.gen
			sed -i 's/#de_DE@euro ISO-8859-15 /de_DE@euro ISO-8859-15 /g' /mnt/etc/locale.gen)

			## Set keymap
			echo $KEYMAP > /mnt/etc/vconsole.conf

			## Set timezone
			ln -sf $TIMEZONE /mnt/etc/localtime
			arch-chroot /mnt/ timedatectl set-local-rtc 0 # set hardware clock

			## Generate localisation settings
			arch-chroot /mnt/ locale-gen

			### User Configuration

			## Set Root password
			arch-chroot /mnt/ sudo sh -c "echo root:'$ROOTPASS' | chpasswd"

			## Create User with password
			arch-chroot /mnt/ useradd -m -G users,wheel -s /bin/bash -p $(openssl passwd -1 $USERPASS) $USERNAME

			## Enable multilib
			sed -i '/^#\[multilib]/{n;s/^#//}' /mnt/etc/pacman.conf
			sed -i '/^#\[multilib]/{s/^#//}' /mnt/etc/pacman.conf
			arch-chroot /mnt/ pacman -Syyu --noconfirm

			## Install yay package manager
			mkdir /mnt/tmp/build
			cd /mnt/tmp/build
			arch-chroot /mnt/ git clone https://aur.archlinux.org/yay.git
			arch-chroot /mnt/ chown -R $USERNAME /tmp/build
			arch-chroot /mnt/ cd yay
			arch-chroot /mnt/ sudo -u $USERNAME makepkg -si --noconfirm
	
			## Install CPU Microcode
			arch-chroot /mnt/ sudo -u $USERNAME yay -S --needed --noconfirm $CPU_MICROCODE

			## Install / Set GPU Driver
			arch-chroot /mnt/ sudo -u $USERNAME yay -S --needed --noconfirm $GPU_DRIVER
			$MODULES_DRIVER

			## Install Compositor /  Window System
			arch-chroot /mnt/ sudo -u $USERNAME yay -S --needed --noconfirm - < pkgLists/systemLists/waylandPkgs.txt
			arch-chroot /mnt/ sudo -u $USERNAME yay -S --needed --noconfirm - < pkgLists/systemLists/x11Pkgs.txt

			## Install Userspace
			for i in ${CHOOSEN_USERSPACE[@]}
			do
				case $i in
					Plasma)
						echo "Add Plasma to installation query..."
						arch-chroot /mnt/ sudo -u $USERNAME yay -S --needed --noconfirm - < pkgLists/desktopLists/plasmaPkgs.txt
					;;
					Gnome)
						echo "Add Gnome to installation query..."
						arch-chroot /mnt/ sudo -u $USERNAME yay -S --needed --noconfirm - < pkgLists/desktopLists/gnomePkgs.txt
					;;
					XFCE)
						echo "Add XFCE to installation query..."
						arch-chroot /mnt/ sudo -u $USERNAME yay -S --needed --noconfirm - < pkgLists/desktopLists/xfcePkgs.txt
					;;
					Sway)
						echo "Add Sway to installation query..."
						arch-chroot /mnt/ sudo -u $USERNAME yay -S --needed --noconfirm - < pkgLists/desktopLists/swayPkgs.txt
						if lshw -C display | grep "NVIDIA"; then
								arch-chroot /mnt/ sudo -u $USERNAME yay -S --needed --noconfirm sway-nvidia
						fi
					;;
					AwesomeWM)
						echo "Add Awesome WM to installation query..."
						arch-chroot /mnt/ sudo -u $USERNAME yay -S --needed --noconfirm - < pkgLists/desktopLists/awesomePkgs.txt
					;;
				esac
			done

			## Install / Set Login-Manager
			if [ $CHOOSEN_LOGINMANAGER == "SDDM" ]; then
					echo "Set LightDM as Login-Manager..."
					arch-chroot /mnt/ systemctl enable sddm
				elif [ $CHOOSEN_LOGINMANAGER == "GDM" ]; then
					echo "Set LightDM as Login-Manager..."
					arch-chroot /mnt/ systemctl enable gdm
				elif [ $CHOOSEN_LOGINMANAGER == "LightDM" ]; then
					echo "Set LightDM as Login-Manager..."
					arch-chroot /mnt/ systemctl enable lightdm
			fi

			## Install Userspace PKGs
			for i in ${CHOOSEN_USERPACKAGES[@]}
			do
				case $i in
					"Base")
						echo "Add Base to installation query..."
						arch-chroot /mnt/ sudo -u $USERNAME yay -S --needed --noconfirm - < pkgLists/softwareLists/basePkgs.txt
					;;
					"Editing")
						echo "Add Editing to installation query..."
						arch-chroot /mnt/ sudo -u $USERNAME yay -S --needed --noconfirm - < pkgLists/softwareLists/editingPkgs.txt
					;;
					"Flatpaks")
						echo "Add Flatpaks to installation query..."
						arch-chroot /mnt/ sudo -u $USERNAME yay -S flatpak
						#arch-chroot /mnt/ sudo -u $USERNAME yay -S --needed --noconfirm - < pkgLists/softwareLists/flatpakPkgs.txt
					;;
					"Gaming")
						echo "Add Gaming to installation query..."
						arch-chroot /mnt/ sudo -u $USERNAME yay -S --needed --noconfirm - < pkgLists/softwareLists/gamingPkgs.txt
					;;
					"Multimedia")
						echo "Add Multimedia to installation query..."
						arch-chroot /mnt/ sudo -u $USERNAME yay -S --needed --noconfirm - < pkgLists/softwareLists/multimediaPkgs.txt
					;;
					"Office")
						echo "Add Office to installation query..."
						arch-chroot /mnt/ sudo -u $USERNAME yay -S --needed --noconfirm - < pkgLists/softwareLists/officePkgs.txt
					;;
					"Printing")
						echo "Add Printing to installation query..."
						arch-chroot /mnt/ sudo -u $USERNAME yay -S --needed --noconfirm - < pkgLists/softwareLists/printPkgs.txt
					;;
					"Privacy")
						echo "Add Privacy to installation query..."
						arch-chroot /mnt/ sudo -u $USERNAME yay -S --needed --noconfirm - < pkgLists/softwareLists/privacyPkgs.txt
					;;
					"Programming")
						echo "Add Programming to installation query..."
						arch-chroot /mnt/ sudo -u $USERNAME yay -S --needed --noconfirm - < pkgLists/softwareLists/programmingPkgs.txt
						#cat pkgLists/softwareLists/vscExt.txt | while read VSC_EXTENSIONS || [[ -n $VSC_EXTENSIONS ]];
						#do
						#	code --install-extension $VSC_EXTENSIONS --force
						#done
					;;
					"Server")
						echo "Add Server to installation query..."
						arch-chroot /mnt/ sudo -u $USERNAME yay -S --needed --noconfirm - < pkgLists/softwareLists/serverPkgs.txt
					;;
					"Tools")
						echo "Add Toosl to installation query..."
						arch-chroot /mnt/ sudo -u $USERNAME yay -S --needed --noconfirm - < pkgLists/softwareLists/toolsPkgs.txt
					;;
					"VM")
						echo "Add VM to installation query..."
						arch-chroot /mnt/ sudo -u $USERNAME yay -S --needed --noconfirm - < pkgLists/softwareLists/vmPkgs.txt
						sed -i 's/#unix_sock_group = "libvirt"/unix_sock_group = "libvirt"/g' /mnt/etc/libvirt/libvirtd.conf
						sed -i 's/#unix_sock_rw_perms = "0770"/unix_sock_rw_perms = "0770"/g' /mnt/etc/libvirt/libvirtd.conf
						arch-chroot /mnt/ gpasswd -a $USERNAME libvirt
						arch-chroot /mnt/ systemctl enable libvirtd
					;;	
				esac
			done

			## Enable system services
			systemctl enable firewalld
			systemctl enable cpupower
			
			
			systemctl enable watchdog
			systemctl enable httpd
			systemctl enable cups
			systemctl enable tlp
			#systemctl enable snapd
			systemctl enable bluetooth
			#systemctl enable samba
			#systemctl enable avahi-daemon

			## Setup Firewalld as system wide firewall

			## Generate mkinitcpio.conf




			## Change sudo for user(s) to normal
			sed -i 's/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/#%wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /mnt/etc/sudors
			sed -i 's/#%wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' /mnt/etc/sudors

			## Reboot system
			whiptail --title "Installation is complete" --yesno "Restart computer?)" 32 128 3>&1 1>&2 2>&3

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


