#!/bin/bash
#
cp config.base config.txt
echo gpu_mem=320 >> config.txt
sudo cp config.txt /boot/
#sudo systemctl disable pacman-script
sudo systemctl enable kodi
sync
sudo reboot
