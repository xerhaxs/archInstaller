#! /bin/bash

## This is an installation script for a customizing your Arch Linux. It is modified for my personal needs. Feel free to use or customize!



###
### ---- Start: Define functions for this installation script ----
###



## Function to configurate the Desktop environment / Window Manager
function_select_enviroment() {
	CHOSEN_USERSPACE=$(whiptail --title "Package Selection" --checklist "Which desktop environment or window manager do you want to install?" 32 128 16 \
	'Plasma'		'X11 + Wayland' 	off \
	'Gnome' 		'X11 + Wayland' 	off \
	'XFCE' 			'X11' 				off \
	'Sway' 			'Wayland' 			off \
	'AwesomeWM' 	'X11' 				off \
	3>&1 1>&2 2>&3)

	echo $CHOSEN_USERSPACE
}

## Function to configurate the Login-Manager
function_select_login_manager() {
	CHOSEN_LOGINMANAGER=$(whiptail --title "Package Selection" --radiolist "Which Login-Manager do you want to use?" 32 128 16 \
	'SDDM'		'Recommended for Plasma' 	on 	\
	'GDM' 		'Recommended for Gnomme' 	off \
	'LightDM' 	'Recommended for XFCE'	 	off \
	3>&1 1>&2 2>&3)

	echo $CHOSEN_LOGINMANAGER
}

## Function to configurate user specific packages
function_select_package() {
	CHOSEN_USERPACKAGES=$(whiptail --title "Package Selection" --checklist "Which desktop environment or window manager do you want to install?" 32 128 16 \
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

	echo $CHOSEN_USERPACKAGES
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

## Function to configurate the system wide theming
function_select_theme() {
	CHOSEN_THEME=$(whiptail --title "Theming" --radiolist "Which system wide theme do you prefer?" 32 128 16 \
	'Default'				'Default theme - No modifications'	on	\
	'Catppuccin Latte'		'Light theme'						off	\
	'Catppuccin Frappé'		'Light dark theme'					off	\
	'Catppuccin Macchiato'	'Dark theme'						off	\
	'Catppuccin Mocha'		'Dark dark theme'					off	\
	3>&1 1>&2 2>&3)

	echo $CHOSEN_THEME
}

## Function to configurate the timeshift backup system
function_timeshift_setup() {
	# Set the backup directory
	backup_dir="/mnt/backup"

	# Set the backup frequency
	backup_frequency=$(whiptail --title "Backup Frequency" --menu "Choose how often you want to backup:" 15 60 4 \
			"1" "Daily" \
			"2" "Weekly" \
			"3" "Monthly" \
			"4" "Yearly" 3>&1 1>&2 2>&3)

	# Set the backup time
	backup_time=$(whiptail --title "Backup Time" --inputbox "Enter the time you want to backup (HH:MM):" 10 60 3>&1 1>&2 2>&3)

	# Set the backup retention period
	backup_retention=$(whiptail --title "Backup Retention Period" --inputbox "Enter the number of backups you want to keep:" 10 60 3>&1 1>&2 2>&3)

	# Create the backup schedule
	case $backup_frequency in
		"1") cron_schedule="0 $backup_time * * *";;
		"2") cron_schedule="0 $backup_time * * 0";;
		"3") cron_schedule="0 $backup_time 1 * *";;
		"4") cron_schedule="0 $backup_time 1 1 *";;
	esac

	# Create the backup script
	echo "#!/bin/bash" > /usr/local/bin/timeshift-backup.sh
	echo "" >> /usr/local/bin/timeshift-backup.sh
	echo "# Run timeshift with the specified parameters" >> /usr/local/bin/timeshift-backup.sh
	echo "/usr/bin/timeshift --create --comments \"Automated backup\" --tags DAILY --scripted --snapshot-device /dev/sda1 --snapshot-boot --exclude /mnt/backup/* --exclude /home/*/.cache/* --exclude /var/tmp/* --exclude /var/cache/* --exclude /var/log/* --exclude /var/backups/* --exclude /var/lib/docker/* --exclude /var/lib/snapd/*" >> /usr/local/bin/timeshift-backup.sh

	# Make the script executable
	chmod +x /usr/local/bin/timeshift-backup.sh

	# Add the script to crontab
	(crontab -l ; echo "$cron_schedule /usr/local/bin/timeshift-backup.sh") | crontab -
}



###
### ---- End: Define functions for this installation script ----
###

###
### ---- Start: Configuration of the system ----
###



function_select_enviroment

function_select_login_manager

function_select_package

function_select_portable_device_optimization

function_select_theme

## Install yay package manager
mkdir ~/build
cd  ~/build
git clone https://aur.archlinux.org/yay.git
cd ~/build/yay
makepkg -si --noconfirm


## Install System Packages
yay -S --needed --noconfirm - < pkgLists/systemLists/systemPkgs.txt

			## Install Battery & Tocuh optimizations for portable devices
			if [ $BATTERY_OPTIMIZATION == true ]; then
					arch-chroot /mnt/ sudo -u $CHROOTUSERNAME yay -S --needed --noconfirm - < pkgLists/driverLists/laptopPkgs.txt
					arch-chroot /mnt/ systemctl enable cpupower
					arch-chroot /mnt/ systemctl enable tlp
					# Librewolf enable touch support
					echo 'MOZ_USE_XINPUT2 DEFAULT=1' > /etc/security/pam_env.conf
					#c6-Suspendbugfix (For some AMD-Systems)
					#arch-chroot /mnt/ modprobe msr
					#arch-chroot /mnt/ sh -c "echo msr > /etc/modules-load.d/msr.conf"
					#arch-chroot /mnt/ sudo -u $CHROOTUSERNAME yay -S disable-c6-systemd
					#arch-chroot /mnt/ systemctl enable disable-c6.service
			fi
			
			## Install Userspace
			for i in ${CHOSEN_USERSPACE[@]}
			do
				case $i in
					Plasma)
						echo "Add Plasma to installation query..."
						arch-chroot /mnt/ sudo -u $CHROOTUSERNAME yay -S --needed --noconfirm - < pkgLists/desktopLists/plasmaPkgs.txt
						arch-chroot 
						# install vlc dolphin addon + metadata remover dolphin addon
						#mkdir /home/$CHROOTUSERNAME/.local/share/kservices5/ServiceMenus/
						#cd /home/$CHROOTUSERNAME/build
						#git clone https://github.com/Merrit/kde-dolphin-remove-metadata.git
						#cd kde-dolphin-remove-metadata
						#cp -r removeMetadata.desktop /home/$CHROOTUSERNAME/.local/share/kservices5/ServiceMenus/
						#cd /home/$CHROOTUSERNAME/build
						#git clone https://github.com/rc2dev/KDE-ServiceMenus.git
						#cd KDE-ServiceMenus
						#cp -r *.desktop /home/$CHROOTUSERNAME/.local/share/kservices5/ServiceMenus/
						#arch-chroot /mnt/ firewall-cmd --permanent --zone=home --add-service=kdeconnect
					;;
					Gnome)
						echo "Add Gnome to installation query..."
						arch-chroot /mnt/ sudo -u $CHROOTUSERNAME yay -S --needed --noconfirm - < pkgLists/desktopLists/gnomePkgs.txt
						arch-chroot /mnt/ firewall-cmd --permanent --zone=home --add-service=kdeconnect
					;;
					XFCE)
						echo "Add XFCE to installation query..."
						arch-chroot /mnt/ sudo -u $CHROOTUSERNAME yay -S --needed --noconfirm - < pkgLists/desktopLists/xfcePkgs.txt
					;;
					Sway)
						echo "Add Sway to installation query..."
						arch-chroot /mnt/ sudo -u $CHROOTUSERNAME yay -S --needed --noconfirm - < pkgLists/desktopLists/swayPkgs.txt
						if lshw -C display | grep "NVIDIA"; then
								arch-chroot /mnt/ sudo -u $CHROOTUSERNAME yay -S --needed --noconfirm sway-nvidia
						fi
					;;
					AwesomeWM)
						echo "Add Awesome WM to installation query..."
						arch-chroot /mnt/ sudo -u $CHROOTUSERNAME yay -S --needed --noconfirm - < pkgLists/desktopLists/awesomePkgs.txt
					;;
				esac
			done

			## Install / Set Login-Manager
			if [ $CHOSEN_LOGINMANAGER == "SDDM" ]; then
					echo "Set LightDM as Login-Manager..."
					arch-chroot /mnt/ systemctl enable sddm
					arch-chroot /mnt/ sudo -u $CHROOTUSERNAME yay -S --needed --noconfirm sddm-catppuccin-git
				elif [ $CHOSEN_LOGINMANAGER == "GDM" ]; then
					echo "Set LightDM as Login-Manager..."
					arch-chroot /mnt/ systemctl enable gdm
				elif [ $CHOSEN_LOGINMANAGER == "LightDM" ]; then
					echo "Set LightDM as Login-Manager..."
					arch-chroot /mnt/ systemctl enable lightdm
			fi

			## Install / Set system theme
			arch-chroot /mnt/ sudo -u $CHROOTUSERNAME yay -S --needed --noconfirm - < pkgLists/themeLists/themePkgs.txt
			if [ $CHOSEN_THEME == "Default" ]; then
					echo "Set system theme to Default..."
				elif [ $CHOSEN_THEME == "Catppuccin Latte" ]; then
					echo "Set system theme to Catppuccin Latte..."
					arch-chroot /mnt/ sudo -u $CHROOTUSERNAME yay -S --needed --noconfirm - < pkgLists/themeLists/catppuccinLattePkgs.txt
					arch-chroot /mnt/ plymouth-set-default-theme -R catppuccin-latte
					ln -sf ”/usr/share/themes/Catppuccin-Latte-Standard-Mauve-Dark/gtk-4.0/assets” ”/usr/share/gtk-4.0/assets”
					ln -sf ”/usr/share/themes/Catppuccin-Latte-Standard-Mauve-Dark/gtk-4.0/gtk.css” ”/usr/share/gtk-4.0/gtk.css”
					ln -sf "/usr/share/themes/Catppuccin-Latte-Standard-Mauve-Dark/gtk-4.0/gtk-dark.css” "/usr/share/gtk-4.0/gtk-dark.css”
				elif [ $CHOSEN_THEME == "Catppuccin Frappé" ]; then
					echo "Set system theme to Catppuccin Frappé..."
					arch-chroot /mnt/ sudo -u $CHROOTUSERNAME yay -S --needed --noconfirm - < pkgLists/themeLists/catppuccinFrappePkgs.txt
					arch-chroot /mnt/ plymouth-set-default-theme -R catppuccin-frappe
					ln -sf ”/usr/share/themes/Catppuccin-Frappe-Standard-Mauve-Dark/gtk-4.0/assets” ”/usr/share/gtk-4.0/assets”
					ln -sf ”/usr/share/themes/Catppuccin-Frappe-Standard-Mauve-Dark/gtk-4.0/gtk.css” ”/usr/share/gtk-4.0/gtk.css”
					ln -sf "/usr/share/themes/Catppuccin-Frappe-Standard-Mauve-Dark/gtk-4.0/gtk-dark.css” "/usr/share/gtk-4.0/gtk-dark.css”
				elif [ $CHOSEN_THEME == "Catppuccin Macchiato" ]; then
					echo "Set system theme to Catppuccin Macchiato..."
					arch-chroot /mnt/ sudo -u $CHROOTUSERNAME yay -S --needed --noconfirm - < pkgLists/themeLists/catppuccinMacchiatoPkgs.txt
					arch-chroot /mnt/ plymouth-set-default-theme -R catppuccin-macchiato
					ln -sf ”/usr/share/themes/Catppuccin-Macchiato-Standard-Mauve-Dark/gtk-4.0/assets” ”/usr/share/gtk-4.0/assets”
					ln -sf ”/usr/share/themes/Catppuccin-Macchiato-Standard-Mauve-Dark/gtk-4.0/gtk.css” ”/usr/share/gtk-4.0/gtk.css”
					ln -sf "/usr/share/themes/Catppuccin-Macchiato-Standard-Mauve-Dark/gtk-4.0/gtk-dark.css” "/usr/share/gtk-4.0/gtk-dark.css”
				elif [ $CHOSEN_THEME == "Catppuccin Mocha" ]; then
					echo "Set system theme to Catppuccin Mocha..."
					arch-chroot /mnt/ sudo -u $CHROOTUSERNAME yay -S --needed --noconfirm - < pkgLists/themeLists/catppuccinMochaPkgs.txt
					arch-chroot /mnt/ plymouth-set-default-theme -R catppuccin-mocha
					ln -sf ”/usr/share/themes/Catppuccin-Mocha-Standard-Mauve-Dark/gtk-4.0/assets” ”/usr/share/gtk-4.0/assets”
					ln -sf ”/usr/share/themes/Catppuccin-Mocha-Standard-Mauve-Dark/gtk-4.0/gtk.css” ”/usr/share/gtk-4.0/gtk.css”
					ln -sf "/usr/share/themes/Catppuccin-Mocha-Standard-Mauve-Dark/gtk-4.0/gtk-dark.css” "/usr/share/gtk-4.0/gtk-dark.css”
			fi

			## Install Userspace PKGs
			for i in ${CHOSEN_USERPACKAGES[@]}
			do
				case $i in
					"Base")
						echo "Add Base to installation query..."
						arch-chroot /mnt/ sudo -u $CHROOTUSERNAME yay -S --needed --noconfirm - < pkgLists/softwareLists/basePkgs.txt
					;;
					"Editing")
						echo "Add Editing to installation query..."
						arch-chroot /mnt/ sudo -u $CHROOTUSERNAME yay -S --needed --noconfirm - < pkgLists/softwareLists/editingPkgs.txt
					;;
					"Flatpaks")
						echo "Add Flatpaks to installation query..."
						arch-chroot /mnt/ sudo -u $CHROOTUSERNAME yay -S flatpak
						## Configure theming for Flatpaks
						arch-chroot /mnt/ sudo flatpak override --filesystem=$HOME/.themes
						arch-chroot /mnt/ sudo flatpak override --env=GTK_THEME=##theme##
						## Install Flatpaks
						arch-chroot /mnt/ sudo -u $CHROOTUSERNAME yay -S --needed --noconfirm - < pkgLists/softwareLists/flatpakPkgs.txt
						## Install custom asar-file for Discord
						rm /var/lib/flatpak/app/com.discordapp.Discord/current/active/files/discord/resources/app.asar
						wget -c https://github.com/GooseMod/OpenAsar/releases/download/nightly/app.asar -P /var/lib/flatpak/app/com.discordapp.Discord/current/active/files/discord/resources/
					;;
					"Gaming")
						echo "Add Gaming to installation query..."
						arch-chroot /mnt/ sudo -u $CHROOTUSERNAME yay -S --needed --noconfirm - < pkgLists/softwareLists/gamingPkgs.txt
					;;
					"Multimedia")
						echo "Add Multimedia to installation query..."
						arch-chroot /mnt/ sudo -u $CHROOTUSERNAME yay -S --needed --noconfirm - < pkgLists/softwareLists/multimediaPkgs.txt
					;;
					"Office")
						echo "Add Office to installation query..."
						arch-chroot /mnt/ sudo -u $CHROOTUSERNAME yay -S --needed --noconfirm - < pkgLists/softwareLists/officePkgs.txt
					;;
					"Printing")
						echo "Add Printing to installation query..."
						arch-chroot /mnt/ sudo -u $CHROOTUSERNAME yay -S --needed --noconfirm - < pkgLists/softwareLists/printPkgs.txt

						arch-chroot /mnt/ systemctl enable cups

						arch-chroot /mnt/ firewall-cmd --permanent --zone=home --add-service=ipp-client
						arch-chroot /mnt/ firewall-cmd --permanent --zone=home --add-service=mdns
						arch-chroot /mnt/ firewall-cmd --permanent --zone=home --add-service=sane
						# Enable Canon 4400F
						sed -i 's/#usb 0x04a9 0x2228/usb 0x04a9 0x2228/g' /mnt/etc/sane.d/genesys.conf
					;;
					"Privacy")
						echo "Add Privacy to installation query..."
						arch-chroot /mnt/ sudo -u $CHROOTUSERNAME yay -S --needed --noconfirm - < pkgLists/softwareLists/privacyPkgs.txt
						firewalld-cmd --set-default=public
						systemctl enable portmaster
					;;
					"Programming")
						echo "Add Programming to installation query..."
						arch-chroot /mnt/ sudo -u $CHROOTUSERNAME yay -S --needed --noconfirm - < pkgLists/softwareLists/programmingPkgs.txt

						EXTENSION_FILE="vscExt.txt"
						while IFS= read -r EXTENSION; do
							code --install-extension "$EXTENSION"
						done < "$EXTENSION_FILE"
					;;
					"Server")
						echo "Add Server to installation query..."
						arch-chroot /mnt/ sudo -u $CHROOTUSERNAME yay -S --needed --noconfirm - < pkgLists/softwareLists/serverPkgs.txt
						
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
						arch-chroot /mnt/ sudo -u $CHROOTUSERNAME yay -S --needed --noconfirm - < pkgLists/softwareLists/toolsPkgs.txt
					;;
					"VM")
						echo "Add VM to installation query..."
						arch-chroot /mnt/ sudo -u $CHROOTUSERNAME yay -S --needed --noconfirm - < pkgLists/softwareLists/vmPkgs.txt

						sed -i 's/#unix_sock_group = "libvirt"/unix_sock_group = "libvirt"/g' /mnt/etc/libvirt/libvirtd.conf
						sed -i 's/#unix_sock_rw_perms = "0770"/unix_sock_rw_perms = "0770"/g' /mnt/etc/libvirt/libvirtd.conf

						arch-chroot /mnt/ gpasswd -a $CHROOTUSERNAME libvirt
						arch-chroot /mnt/ systemctl enable libvirtd
					;;	
				esac
			done

			## Enable system services
			

			#systemctl enable snapd
			systemctl enable bluetooth