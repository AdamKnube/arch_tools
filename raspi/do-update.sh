#!/bin/bash
#
cp config.base config.txt
echo gpu_mem=16 >> config.txt
sudo cp config.txt /boot/
sudo systemctl disable kodi
#sudo systemctl enable pacman-script
sync
sudo reboot
