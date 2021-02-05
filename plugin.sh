disk=`cat /proc/partitions|grep 87908|grep sd|awk '{print $4}'|shuf -n 1`
mountpoint=`lsblk |grep -A 1 $disk|grep oss|awk '{print $7}'`

echo -e "`date` | plugin disk choice $disk"
i=$disk;echo offline >/sys/block/$i/device/state;echo 1 >/sys/block/$i/device/delete
sleep 20

osdid=`yrcli --osd --type=oss|grep warning|awk '{print $1}'`
nodeid=`yrcli --osd --type=oss|grep warning|awk '{print $3}'`
echo -e "`date` disk $disk, osdid $osdid, nodeid $nodeid, mountpoint $mountpoint"
if [[ -z $nodeid ]];then
    echo -e "not found usable osd!"
    exit
fi

echo "- - -" > /sys/class/scsi_host/host0/scan
echo -e "`date` rescanning disk"
sleep 2

newdisk=`cat /proc/partitions|grep -v bcache|tail -n 1|awk '{print $4}'`
echo -e "`date` newdisk path is $newdisk"

yrcli --rmosd --osdid=$osdid
if [[ $? -ne 0 ]];then
   echo -e "`date` rmosd faild"
   exit
fi

umount $mountpoint
if [[ $? -ne 0 ]];then
   echo -e "`date` umount $mountpoint failed"
   exit
fi

echo -e "repair bache"
echo 1 > /sys/block/$newdisk/bcache/stop
echo "/dev/$newdisk" > /sys/fs/bcache/register

mount -a

echo -e "`date` add osd"
yrcli --addosd --nodeid=$nodeid --osdpath=$mountpoint
if [[ $? -ne 0 ]];then
   echo -e "`date` add osd faild"
   exit
fi
