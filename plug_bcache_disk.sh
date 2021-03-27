plug(){
    bcache=`cat /proc/partitions |grep 46885|awk '{print $4}'`
    disk=`cat /proc/partitions |grep 87908|grep -v bcache|awk '{print $4}'` 
    uuid=`bcache-super-show /dev/$bcache|grep cset.uuid|awk '{print $2}'`
    
    for i in $bcache $disk;do
        echo -e "`date`\t $i offline."
        echo offline >/sys/block/$i/device/state;echo 1 >/sys/block/$i/device/delete
    done
    sleep 60
    echo -e "`date`\t disk scan"
    echo "- - -" > /sys/class/scsi_host/host0/scan
}

attach(){
    systemctl stop yrfs-storage
    umount /data/oss*
    ssd=`cat /proc/partitions |grep 46885|awk '{print $4}'`
    disk=`cat /proc/partitions |grep 87908|grep -v bcache|awk '{print $4}'` 
    uuid=`bcache-super-show /dev/$bcache|grep cset.uuid|awk '{print $2}'`

    echo -e "ssd $ssd register."
    echo /dev/$ssd > /sys/fs/bcache/register

    for disk in $disk;do
        echo -e "`date`\t hdd $disk attach $uuid."
        echo $uuid > /sys/block/$disk/bcache/attach
    done
   
    for disk in $ssd;do 
        echo -e "`date`\t repair $disk" 
        xfs_repair -L /dev/$disk
    done
    echo -e "`date`\t mount disk"
    mount -a
    systemctl start yrfs-storage
}
plug
sleep 5
attach
