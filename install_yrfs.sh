#!/bin/bash

ossdisk=`lsblk |grep 838|awk '{print $1}'`
mdsdisk=`lsblk |grep 894|awk '{print $1}'`

rebuild(){
    if [[ -z $1 ]];then
        echo -e "host num must need!!!"
        exit
    fi
    
    n=$1
    
    etcdctl del --prefix=true /yrcf/
    ps axu|grep -E "yrfs-meta|yrfs-mgmtd|yrfs-storage|yrfs-admon"|grep -v grep|awk '{print $2}'|xargs -I {} kill -9 {}
    
    sed -i "/^.*oss.*$/d" /etc/fstab
    oss=0
    
    for disk in $ossdisk;do
        echo -e "$disk"
        mountdir="/data/oss${oss}"
        oss_id=$n"00"$((oss+1))
        
        findmnt $mountdir
        if [[ $? -eq 0 ]];then
            umount $mountdir
        fi
        
        if [[ -d $mountdir ]];then 
            rm -fr $mountdir 
        fi
    
        mkdir -p $mountdir 
        echo -e "host id: $n oss_id: $oss_id"
        
        mkfs.xfs -d su=128k,sw=8 -l version=2,su=128k -isize=512 -f /dev/$disk
        
        echo `blkid /dev/$disk|awk '{print $2}'` /data/oss${oss} xfs defaults,prjquota,allocsize=8M,noatime,nodiratime,logbufs=8,logbsize=256k,largeio,inode64,swalloc,nofail,x-systemd.device-timeout=5 0 0 >> /etc/fstab
        systemctl daemon-reload
        mount -a
        /usr/local/sbin/yrfs-setup-storage -p /data/oss${oss} -S node${n}-stor -s $n -i $oss_id -I tg$oss_id -z 0 -m 19.45.12.11,19.45.12.12,19.45.12.13 -f
        ((oss++))
    
    done
    
    sed -i "/^.*mds.*$/d" /etc/fstab
    mds=0
    for disk in $mdsdisk;do
         mountdir="/data/mds${mds}"
    
         findmnt $mountdir
         if [[ $? -eq 0 ]];then
             umount $mountdir
         fi
    
         if [[ -d $mountdir ]];then 
             rm -fr $mountdir 
         fi
         mkdir -p $mountdir
    
         #mkfs.xfs -isize=1024 -imaxpct=80 -f /dev/$disk
         mkfs.ext4 -i 1024 -I 512 -J size=4096 -Odir_index,filetype /dev/$disk
    
         #echo `blkid /dev/$disk|awk '{print $2}'` /data/mds$mds xfs defaults,noatime,nodiratime,nofail,x-systemd.device-timeout=5 0 0 >> /etc/fstab
         echo `blkid /dev/$disk|awk '{print $2}'` /data/mds$mds ext4 defaults,noatime,nodiratime,user_xattr,nofail,x-systemd.device-timeout=5 0 0 >> /etc/fstab
         
    
         systemctl daemon-reload
         mount -a
    
         /usr/local/sbin/yrfs-setup-meta -p /data/mds$mds -S node$n-stor -s $n -m 19.45.12.11,19.45.12.12,19.45.12.13 -f
         ((mds++))
    done
}

init(){
    yrcli --addgroup --type=mds --auto;yrcli --addgroup --type=oss --auto
    yrcli --mkfs
    yrcli --acl --op=add --path=/ --ip=* --mode=rw
    yrcli --cliacl --op=add --ip=*
    yrcli --setentry --stripesize=1m --schema=mirror --stripecount=6 / -u
}

bcache(){
    m=0
    disk=""
    bcachedisk=$1
    make-bcache -C $bcachedisk -B $ossdisk
    for i in $ossdisk;do
        echo writeback > /sys/block/bcache$m/bcache/cache_mode
	disk=$disk"bcache$m"
	((m++))
    done	
}
#rebuild $1
init
