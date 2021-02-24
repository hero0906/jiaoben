disk=`cat /proc/partitions|grep 87908|grep sd|awk '{print $4}'|shuf -n 1`
mountpoint=`lsblk |grep -A 1 $disk|grep oss|awk '{print $7}'`
osdid=`cat $mountpoint/targetid`
nodeid=`cat $mountpoint/nodeid`
uuid=`ls /sys/fs/bcache/|grep -`

echo -e "`date` disk $disk, osdid $osdid, nodeid $nodeid, mountpoint $mountpoint"
if [[ -z $nodeid ]] || [[ -z $osdid ]] ;then
    echo -e "not found disk: $disk osdid and nodeid!"
    exit
fi

echo -e "`date` | plugin disk choice $disk"
i=$disk;echo offline >/sys/block/$i/device/state;echo 1 >/sys/block/$i/device/delete
sleep 5


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

echo -e "`date` umount $mountpoint"
umount $mountpoint
if [[ $? -ne 0 ]];then
   echo -e "`date` umount $mountpoint failed"
   exit
fi

echo -e "`date` repair bache"
echo 1 > /sys/block/$newdisk/bcache/stop
if [[ $? -ne 0 ]];then
   echo -e "`date` $newdisk stop bcache failed"
   exit
fi

echo -e "format newdisk: $disk"
mkfs.xfs /dev/$newdisk -f
if [[ $? -ne 0 ]];then
   echo -e "`date` clean $newdisk failed"
   exit
fi

echo -e "`date`|\t $newdisk make bcache"
make-bcache -B /dev/$newdisk
if [[ $? -ne 0 ]];then
   echo -e "`date` $newdisk make bcache failed"
   exit
fi 

echo -e "`date`|\t $newdisk register bcache"
echo "/dev/$newdisk" > /sys/fs/bcache/register
if [[ $? -ne 0 ]];then
   echo -e "`date` $newdisk register bcache failed"
   exit
fi 

newbcache=`cat /proc/partitions |grep bcache|tail -n 1|awk '{print $4}'`
echo -e "`date`|\t $newbcache attach bcache"
echo $uuid > /sys/block/$newbcache/bcache/attach
if [[ $? -ne 0 ]];then
   echo -e "`date`|\t $newdisk attach bcache failed"
   exit
fi

echo -e "mkfs newbcache: $newbcache"
mkfs.xfs -d su=128k,sw=8 -l version=2,su=128k -isize=512 -f /dev/$newbcache
if [[ $? -ne 0 ]];then
   echo -e "`date`|\t $newbcache mkfs failed"
   exit
fi

ossname=`echo $mountpoint|awk -F '/' '{print $3}'`
echo -e "`date`|\t $ossname del from fstab"
sed -i "/^.*$ossname.*$/d" /etc/fstab 

echo `blkid /dev/$newbcache|awk '{print $2}'` $mountpoint xfs defaults,prjquota,allocsize=8M,noatime,nodiratime,logbufs=8,logbsize=256k,largeio,inode64,swalloc,nofail,x-systemd.device-timeout=5 0 0 >> /etc/fstab
echo -e "`date`|\t add $mountpoint to fstab"

echo -e "`date` mount -a"
mount -a
if [[ $? -ne 0 ]];then
    echo -e "`date`|\t mount -a failed"
    exit
fi

echo -e "`date` add osd"
yrcli --addosd --nodeid=$nodeid --osdpath=$mountpoint
if [[ $? -ne 0 ]];then
   echo -e "`date` add osd faild"
   exit
fi
