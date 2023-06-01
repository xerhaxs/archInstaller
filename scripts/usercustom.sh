#! /bin/bash

## Install yay package manager
mkdir ~/build
cd  ~/build
git clone https://aur.archlinux.org/yay.git
cd ~/build/yay
makepkg -si --noconfirm
