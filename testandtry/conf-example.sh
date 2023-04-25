#!/bin/sh

# enable nm


# Backup Folder
cp /etc/locale.conf /etc/recoveryfiles/
cp /etc/locale.gen /etc/recoveryfiles/
cp /etc/mkinitcpio.conf /etc/recoveryfiles/





# mkinicpio.conf
cp /etc/mkinitcpio.conf /etc/recoveryfiles/
echo "# vim:set ft=sh
# MODULES
# The following modules are loaded before any boot hooks are
# run.  Advanced users may wish to specify all system modules
# in this array.  For instance:
#     MODULES=(piix ide_disk reiserfs)
MODULES=(ext4)

# BINARIES
# This setting includes any additional binaries a given user may
# wish into the CPIO image.  This is run last, so it may be used to
# override the actual binaries included by a given hook
# BINARIES are dependency parsed, so you may safely ignore libraries
BINARIES=()

# FILES
# This setting is similar to BINARIES above, however, files are added
# as-is and are not parsed in any way.  This is useful for config files.
FILES=()

# HOOKS
# This is the most important setting in this file.  The HOOKS control the
# modules and scripts added to the image, and what happens at boot time.
# Order is important, and it is recommended that you do not change the
# order in which HOOKS are added.  Run 'mkinitcpio -H <hook name>' for
# help on a given hook.
# 'base' is _required_ unless you know precisely what you are doing.
# 'udev' is _required_ in order to automatically load modules
# 'filesystems' is _required_ unless you specify your fs modules in MODULES
# Examples:
##   This setup specifies all modules in the MODULES setting above.
##   No raid, lvm2, or encrypted root is needed.
#    HOOKS=(base)
#
##   This setup will autodetect all modules for your system and should
##   work as a sane default
#    HOOKS=(base udev autodetect block filesystems)
#
##   This setup will generate a 'full' image which supports most systems.
##   No autodetection is done.
#    HOOKS=(base udev block filesystems)
#
##   This setup assembles a pata mdadm array with an encrypted root FS.
##   Note: See 'mkinitcpio -H mdadm' for more information on raid devices.
#    HOOKS=(base udev block mdadm encrypt filesystems)
#
##   This setup loads an lvm2 volume group on a usb device.
#    HOOKS=(base udev block lvm2 filesystems)
#
##   NOTE: If you have /usr on a separate partition, you MUST include the
#    usr, fsck and shutdown hooks.
HOOKS=(base udev keyboard keymap plymouth encrypt autodetect modconf block lvm2 filesystems resume fsck shutdown)

# COMPRESSION
# Use this to compress the initramfs image. By default, zstd compression
# is used. Use 'cat' to create an uncompressed image.
#COMPRESSION="zstd"
#COMPRESSION="gzip"
#COMPRESSION="bzip2"
#COMPRESSION="lzma"
#COMPRESSION="xz"
#COMPRESSION="lzop"
#COMPRESSION="lz4"

# COMPRESSION_OPTIONS
# Additional options for the compressor
#COMPRESSION_OPTIONS=()" > /etc/mkinitcpio.conf




# X11 local
localectl --no-convert set-keymap de-latin1
localectl --no-convert set-x11-keymap de pc105

echo 'Section "InputClass"
        Identifier "system-keyboard"
        MatchIsKeyboard "on"
        Option "XkbLayout" "de"
EndSection' > /etc/X11/xorg.conf.d/00-keyboard.conf

locale
localectl status





# configurate webdav server
cp /etc/httpd/conf/httpd.conf /etc/recoveryfiles
chmod rw http:httpd -R /run/media/jf/
gpasswd -a $user http
mkdir -p /home/httpd/DAV
chown -R http:http /home/httpd/DAV
mkdir -p /home/httpd/html/dav
chown -R http:http /home/httpd/html/dav

## configurate samba share
mkdir /var/lib/samba/usershares
groupadd -r sambashare
chown root:sambashare /var/lib/samba/usershares
chmod 1770 /var/lib/samba/usershares
useradd -M smbusr
usermod -u 1500 smbusr
gpasswd sambashare -a smbusr
smbpasswd -e smbusr


# setup firewall
firewall-cmd --set-default=home
firewall-cmd --permanent --zone=home --add-service=dhcpv6-client




firewall-cmd --permanent --zone=home --add-service=ssh
firewall-cmd --permanent --zone=home --add-service=syncthing
firewall-cmd --permanent --zone=home --add-service=syncthing-gui
firewall-cmd --permanent --zone=home --add-service=ws-discovery
firewall-cmd --permanent --zone=home --add-service=ws-discovery-client
firewall-cmd --permanent --zone=home --add-service=ws-discovery-tcp
firewall-cmd --permanent --zone=home --add-service=ws-discovery-udp




# librewolf / firefox theming
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/black7375/Firefox-UI-Fix/master/install.sh)"



# install Rust
sudo -u jf rustup install stable && rustup default stable


#flatpak config
#flatpak override --filesystem=/usr/share/themes
#flatpak override --env=GTK_THEME=Breeze-Dark

#enable cron for BackInTime
sudo systemctl enable cronie --now

#config virtuell audio -> pipewire = unnötig
# sudo echo snd_aloop > /etc/modules-load.d/snd_aloop.conf



# setup fancontrolsyn
yes | sensors-detect
#systemctl enable fancontrol

# config awesome

# set plymouth theme
plymouth-set-default-theme -R lone

# gen mkinitcpio
mkinitcpio -p linux




# install rEFInd Bootloader
pacman -S --noconfirm refind
refind-install
mkdir /boot/EFI/refind/themes
cd /boot/EFI/refind/themes
git clone https://github.com/Pr0cella/rEFInd-glassy.git
rm -r /boot/refind_linux.conf

# finale Datein kopieren
cp -r /etc/recoveryfiles/Data/boot/ /
cp -r /etc/recoveryfiles/Data/etc /

