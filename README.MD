### archInstaller

This is my version of an Arch install script with option menus via whiptail. The script is not finished yet - so you might encounter some bugs. ;)
Feel free to use or modify!

#### System requirements

- UEFI / GPT System
- One free disk
- Stable internet connection

#### Usage

To use this installation script, simply download the newest release and make the `archcustom.sh` executable with `chmod +x archcustom.sh`.
Then run the script with `./archcustom.sh` and follow the instructions. Make sure that you are connected to the internet, before starting the script.
The installation script must be executed with root (not sudo)!
After the installation process is done, you can reboot into the new system or chroot to run the usercustom.sh.

Commands:

```
git clone https://github.com/xerhaxs/archInstaller.git
cd archInstaller
chmod +x archcustom.sh
./archcustom.sh
```

#### ToDo

- [X] Create a script which can install Arch Linux with Normal, Zen, LTS and Hardened Kernel
- [ ] Make the script executable via curl
- [ ] Add automatic secure boot installation support
- [ ] Make the installation of the user space changes automatic
- [ ] Add a dotfile-API / Add my custom dotfiles
- [X] Optimize the UX / UI of the script
  - [X] Make “cancel” button in menu useful
  - [X] Change radio lists to menu lists
- [ ] Add support for MBR and BIOS systems
- [X] Add option to securely wipe the installation drive
- [ ] Add GPU support for intel
- [X] Enable fast boot (skip grub menu)
- [ ] Remove the second password entering process for FDE with boot