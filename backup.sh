#!/usr/bin/bash
#
MHOME=$HOME
WHOME=$(hostname)
WHERE2=$1
ITSNOW=Current
if [ $2 = 'fresh' ]; then
    ITSNOW=$(date +%Y%m%d)
fi
sudo ln -s / /root/tmp/$ITSNOW
sudo rsync -avPhe "ssh -i $MHOME/.ssh/backup.ssh" \
--exclude="/proc/*" \
--exclude="/sys/*" \
--exclude="/dev/*" \
--exclude="/tmp/*" \
--exclude="/run/*" \
--exclude="/mnt/*" \
--exclude="/home/*" \
--exclude="/media/*" \
--exclude="/backup/*" \
--exclude="/var/log/*" \
--exclude="/var/tmp/*" \
--exclude="lost+found" \
--exclude="/root/tmp/*" \
/root/tmp/$ITSNOW/ \
$WHERE2/$WHOME/$ITSNOW/
sudo rm /root/tmp/$ITSNOW
