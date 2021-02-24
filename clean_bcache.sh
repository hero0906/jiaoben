#!/bin/bash

#boot_efi=`findmnt | grep boot/efi | awk '{print $2}'`
boot_efi=`findmnt | grep boot | awk '{print $2}'`
sys_disk=`echo ${boot_efi:5:3}`
echo "boot disk : "$sys_disk

disks=`lsblk  | grep -v $sys_disk | grep -E "sd|nvme" | awk '{print $1}'`


echo 'data disk: '$disks

for disk in $disks;do
     if [[ -f '/sys/block/'$disk'/bcache/stop' ]];then
	echo 1 > /sys/block/$disk/bcache/stop
     fi
     cset_uuid=`bcache-super-show /dev/$disk  | grep cset.uuid | awk '{print $2}'`
     if [[ -f '/sys/fs/bcache/'$cset_uuid'/stop'  ]];then
        echo 1 > /sys/fs/bcache/$cset_uuid/stop
     fi
     #expect -c "spawn mkfs.ext4 /dev/$disk;expect *anyway*;send \"y\r\";expect eof" >> /dev/null
     
done
echo "=================================="
echo "|          check disk state      |"
echo "=================================="
for disk in $disks;do
	bcache-super-show /dev/$disk
done
