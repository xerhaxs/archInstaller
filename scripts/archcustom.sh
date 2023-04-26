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
	done < <(localectl list-x11-keymap-layouts)

	CHOOSEN_KBD_LAYOUT=$(whiptail --title "Keyboard Layout" --menu "Pick your keyboard layout (This keyboard layout will only be used during the installation process.)" 32 128 16 "${KBD_OPTIONS[@]}" 3>&1 1>&2 2>&3)
	loadkeys $CHOOSEN_KBD_LAYOUT
}

## Function to detect and set a password
function_password() {
	function_set_password() {
		PASSWORD=$(whiptail --title "Set password" --passwordbox "Choose a strong password." 32 128 3>&1 1>&2 2>&3)

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
}

## Function to set installation disk
function_select_installation_disk() {
	DISKS=$(lsblk | grep disk | awk '{print $1}')

	DISK_OPTIONS=()
	for DISK in $DISKS; do
		DISK_SIZE=$(lsblk "/dev/$DISK" | grep disk | awk '{print $4}')
		DISK_OPTIONS+=("Disk: /dev/$DISK" "Size: $DISK_SIZE")
	done

	CHOOSEN_DRIVE=$(whiptail --title "Menu selected Drive" --menu "Where should Arch Linux be installed?" 32 128 16 "${DISK_OPTIONS[@]}" 3>&1 1>&2 2>&3)

	echo "Choosen Disk: $CHOOSEN_DRIVE"
}

## Function to set the hostname
function_select_hostname() {
	HOSTNAME=$(whiptail --title "Set Hostname" --inputbox "Choose the Hostname of the computer." 32 128 3>&1 1>&2 2>&3)
	echo "Hostname: $HOSTNAME"
}

## Function to set the user credentials
function_select_user_credentials() {
	USERNAME=$(whiptail --title "Create User" --inputbox "Choose your username (only lowercase letters, numbers and no spaces or special characters)" 32 128 3>&1 1>&2 2>&3)
	USERPASS=$(function_password)
}

## Function to configurate the Desktop environment / Window Manager
function_select_enviroment() {
	CHOOSEN_USERSPACE=$(whiptail --title "Package Selection" --checklist "Which desktop environment or window manager do you want to install?" 32 128 16 \
	'Plasma'		'X11 + Wayland' 	off \
	'Gnome' 		'X11 + Wayland' 	off \
	'XFCE' 			'X11' 				off \
	'Sway' 			'Wayland' 			off \
	'AwesomeWM' 	'X11' 				off \
	3>&1 1>&2 2>&3)

	echo $CHOOSEN_USERSPACE
}

## Function to configurate the Login-Manager
function_select_login_manager() {
	CHOOSEN_LOGINMANAGER=$(whiptail --title "Package Selection" --radiolist "Which Login-Manager do you want to use?" 32 128 16 \
	'SDDM'		'Recommended for Plasma' 	on 	\
	'GDM' 		'Recommended for Gnomme' 	off \
	'LightDM' 	'Recommended for XFCE'	 	off \
	3>&1 1>&2 2>&3)

	echo $CHOOSEN_LOGINMANAGER
}

## Function to configurate user specific packages
function_select_package() {
	CHOOSEN_USERPACKAGES=$(whiptail --title "Package Selection" --checklist "Which desktop environment or window manager do you want to install?" 32 128 16 \
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
}

## Function to configurate portable device optimizations
function_select_portable_device_optimization() {
	whiptail --title "Package Selection" --yesno "Do you want to install portable device optimizations like TLP for longer battery life and enable touch support?" 32 128 3>&1 1>&2 2>&3
	if [[ $? -eq 0 ]]; then
			BATTERY_OPTIMIZATION=true
		else
			BATTERY_OPTIMIZATION=false
	fi
}

## Function to configurate the timeshift backup system
function_timeshift_setup() {
	#
	#
	#
	#
}


###
### ---- End: Define functions for this installation script ----
###

###
### ---- Start: Configuration of the system ----
###



function_startup_message

function_start_installation_guide

## Installation guide
function_installation_guide() {


	function_kbd_load

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

	function_select_installation_disk

	parted $CHOOSEN_DRIVE mklabel gpt \
		mkpart primary fat32 1MiB 512MiB \
		set 1 esp on \
		mkpart primary ext4 512MiB 100%




	function_detect_microcode

	function_detect_gpu

	function_select_hostname






	## Define language (For German: LANG=de_DE.UTF-8)
	#LANG=$()
	LANG="LANG=de_DE.UTF-8"
	echo "System language: $LANG"

	LOCALE_FILE="locale.gen"

	LOCALE_OPTIONS=()
	LOCALE_LINE_COUNT=0
	while IFS= read -r LINE
	do
		((LOCALE_LINE_COUNT++))
		if [ $LOCALE_LINE_COUNT -le 17 ] ; then
			continue
		fi
		# Prüfen, ob die Zeile mit einem # beginnt
		if [[ "$LINE" == "#"* ]] ; then
			# Option mit "off" hinzufügen
			LOCALE_OPTIONS+=("${LINE:1}" "" off)
		else
			# Option mit "on" hinzufügen
			LOCALE_OPTIONS+=("$LINE" "" on)
		fi
	done < "$LOCALE_FILE"

	# Whiptail-Checkliste anzeigen und Auswahl speichern
	CHOOSEN_LOCALS=$(whiptail --title "Textoptionen" --checklist "Wählen Sie die gewünschten Optionen:" 15 50 5 "${LOCALE_OPTIONS[@]}" 3>&1 1>&2 2>&3)

	# Ausgewählte Optionen ausgeben
	echo "Sie haben folgende Optionen ausgewählt: $CHOOSEN_LOCALS"

	# Optionen für Whiptail-Checkliste erstellen
	OPTIONS=()
	while IFS= read -r LINE
	do
		# Check if line starts with a #
		if [[ "$LINE" == \#* ]] ; then
			# Check if the option is selected
			if [[ "$LINE" == *\#${CHOOSEN_LOCALS}\#* ]] ; then
				# Remove # from the line and add to options
				LINE="${LINE:1}"
			else
				continue
			fi
		else
			# Check if the option is not selected
			if [[ "$LINE" == *\#${CHOOSEN_LOCALS}\#* ]] ; then
				LINE="${LINE:2}"
			else
				LINE="# $LINE"
			fi
		fi
		OPTIONS+=("$LINE")
	done < "$LOCALE_FILE"

	

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
	ROOTPASS=$(function_password)

	function_select

	function_select_user_credentials

	function_select_enviroment

	function_select_login_manager

	function_select_package

	function_select_portable_device_optimization

	## Configuration of system wide theming
	CHOOSEN_THEME=$(whiptail --title "Theming" --radiolist "Which system wide theme do you prefer?" 32 128 16 \
	\
	'Default'				'Default theme - No modifications'	on	\
	'Catppuccin Latte'		'Light theme'						off	\
	'Catppuccin Frappé'		'Light dark theme'					off	\
	'Catppuccin Macchiato'	'Dark theme'						off	\
	'Catppuccin Mocha'		'Dark dark theme'					off\
	3>&1 1>&2 2>&3)
	echo $CHOOSEN_THEME


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

			## Enable chaotic-aur
			arch-chroot /mnt/ pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com
			arch-chroot /mnt/ pacman-key --lsign-key FBA220DFC880C036
			arch-chroot /mnt/ pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
			echo -e "[chaotic-aur] \nInclude = /etc/pacman.d/chaotic-mirrorlist" | tee -a /mnt/etc/pacman.conf

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

			## Install System Packages
			arch-chroot /mnt/ sudo -u $USERNAME yay -S --needed --noconfirm - < pkgLists/systemLists/systemPkgs.txt
			arch-chroot /mnt/ systemctl enable firewalld
			arch-chroot /mnt/ systemctl enable watchdog

			## Install Battery & Tocuh optimizations for portable devices
			if [ $BATTERY_OPTIMIZATION == true ]; then
					arch-chroot /mnt/ sudo -u $USERNAME yay -S --needed --noconfirm - < pkgLists/driverLists/laptopPkgs.txt
					arch-chroot /mnt/ systemctl enable cpupower
					arch-chroot /mnt/ systemctl enable tlp
					# Librewolf enable touch support
					echo 'MOZ_USE_XINPUT2 DEFAULT=1' > /etc/security/pam_env.conf
					#c6-Suspendbugfix (For some AMD-Systems)
					#arch-chroot /mnt/ modprobe msr
					#arch-chroot /mnt/ sh -c "echo msr > /etc/modules-load.d/msr.conf"
					#arch-chroot /mnt/ sudo -u $USERNAME yay -S disable-c6-systemd
					#arch-chroot /mnt/ systemctl enable disable-c6.service
			fi
			
			## Install Userspace
			for i in ${CHOOSEN_USERSPACE[@]}
			do
				case $i in
					Plasma)
						echo "Add Plasma to installation query..."
						arch-chroot /mnt/ sudo -u $USERNAME yay -S --needed --noconfirm - < pkgLists/desktopLists/plasmaPkgs.txt
						arch-chroot 
						# install vlc dolphin addon + metadata remover dolphin addon
						#mkdir /home/$USERNAME/.local/share/kservices5/ServiceMenus/
						#cd /home/$USERNAME/build
						#git clone https://github.com/Merrit/kde-dolphin-remove-metadata.git
						#cd kde-dolphin-remove-metadata
						#cp -r removeMetadata.desktop /home/$USERNAME/.local/share/kservices5/ServiceMenus/
						#cd /home/$USERNAME/build
						#git clone https://github.com/rc2dev/KDE-ServiceMenus.git
						#cd KDE-ServiceMenus
						#cp -r *.desktop /home/$USERNAME/.local/share/kservices5/ServiceMenus/
						#arch-chroot /mnt/ firewall-cmd --permanent --zone=home --add-service=kdeconnect
					;;
					Gnome)
						echo "Add Gnome to installation query..."
						arch-chroot /mnt/ sudo -u $USERNAME yay -S --needed --noconfirm - < pkgLists/desktopLists/gnomePkgs.txt
						arch-chroot /mnt/ firewall-cmd --permanent --zone=home --add-service=kdeconnect
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
					echo "Set LightDM as Login-Manager..."ryzen 5625 u
					arch-chroot /mnt/ systemctl enable lightdm
			fi


			## Install / Set system theme
			if [ $CHOOSEN_THEME == "Default" ]; then
					echo "Set system theme to Default..."
				elif [ $CHOOSEN_THEME == "Catppuccin Latte" ]; then
					echo "Set system theme to Catppuccin Latte..."
					
				elif [ $CHOOSEN_THEME == "Catppuccin Frappé" ]; then
					echo "Set system theme to Catppuccin Frappé..."

				elif [ $CHOOSEN_THEME == "Catppuccin Macchiato" ]; then
					echo "Set system theme to Catppuccin Macchiato..."

				elif [ $CHOOSEN_THEME == "Catppuccin Mocha" ]; then
					echo "Set system theme to Catppuccin Mocha..."

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
						## Configure theming for Flatpaks
						arch-chroot /mnt/ sudo flatpak override --filesystem=$HOME/.themes
						arch-chroot /mnt/ sudo flatpak override --env=GTK_THEME=##theme##
						## Install Flatpaks
						arch-chroot /mnt/ sudo -u $USERNAME yay -S --needed --noconfirm - < pkgLists/softwareLists/flatpakPkgs.txt
						## Install custom asar-file for Discord
						rm /var/lib/flatpak/app/com.discordapp.Discord/current/active/files/discord/resources/app.asar
						wget -c https://github.com/GooseMod/OpenAsar/releases/download/nightly/app.asar -P /var/lib/flatpak/app/com.discordapp.Discord/current/active/files/discord/resources/
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

						arch-chroot /mnt/ systemctl enable cups

						arch-chroot /mnt/ firewall-cmd --permanent --zone=home --add-service=ipp-client
						arch-chroot /mnt/ firewall-cmd --permanent --zone=home --add-service=mdns
						arch-chroot /mnt/ firewall-cmd --permanent --zone=home --add-service=sane
						# Enable Canon 4400F
						sed -i 's/#usb 0x04a9 0x2228/usb 0x04a9 0x2228/g' /mnt/etc/sane.d/genesys.conf
					;;
					"Privacy")
						echo "Add Privacy to installation query..."
						arch-chroot /mnt/ sudo -u $USERNAME yay -S --needed --noconfirm - < pkgLists/softwareLists/privacyPkgs.txt
						firewalld-cmd --set-default=public
					;;
					"Programming")
						echo "Add Programming to installation query..."
						arch-chroot /mnt/ sudo -u $USERNAME yay -S --needed --noconfirm - < pkgLists/softwareLists/programmingPkgs.txt

						EXTENSION_FILE="vscExt.txt"
						while IFS= read -r EXTENSION; do
							code --install-extension "$EXTENSION"
						done < "$EXTENSION_FILE"
					;;
					"Server")
						echo "Add Server to installation query..."
						arch-chroot /mnt/ sudo -u $USERNAME yay -S --needed --noconfirm - < pkgLists/softwareLists/serverPkgs.txt
						
						arch-chroot /mnt/ systemctl enable httpd
						arch-chroot /mnt/ systemctl enable samba
						arch-chroot /mnt/ systemctl enable avahi-daemon

						arch-chroot /mnt/ firewall-cmd --permanent --zone=home --add-service=http
						arch-chroot /mnt/ firewall-cmd --permanent --zone=home --add-service=https
						arch-chroot /mnt/ firewall-cmd --permanent --zone=home --add-service={samba,samba-client,samba-dc}
						arch-chroot /mnt/ firewall-cmd --permanent --zone=libvirt --add-service=http
						arch-chroot /mnt/ firewall-cmd --permanent --zone=libvirt --add-service=https
						arch-chroot /mnt/ firewall-cmd --permanent --zone=libvirt --add-service={samba,samba-client,samba-dc}


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
			

			#systemctl enable snapd
			systemctl enable bluetooth


			## Setup Firewalld as system wide firewall
			

			## Generate mkinitcpio.conf
			


			arch-chroot /mnt/ mkinitcpio -p $

			## Change sudo for user(s) to normal
			sed -i 's/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/#%wheel ALL=(ALL:ALL) NOPASSWD: ALL/g' /mnt/etc/sudors
			sed -i 's/#%wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' /mnt/etc/sudors

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


