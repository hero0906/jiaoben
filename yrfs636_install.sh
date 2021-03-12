#!/bin/bash



rebuild(){
    n=$1

    if [[ -z $1 ]];then
        echo -e "host num must need!!!"
        exit
    fi

    ossdisk=`lsblk |grep oss|awk '{print $1}'`
    mdsdisk=`lsblk |grep mds|awk '{print $1}'`
    mgmthost="10.20.0.2,10.20.0.3,10.20.0.4"
    
    etcdctl del --prefix=true /yrcf/
    ps axu|grep -E "yrfs-meta|yrfs-mgmtd|yrfs-storage|yrfs-admon"|grep -v grep|awk '{print $2}'|xargs -I {} kill -9 {}
    
    sed -i "/^.*oss.*$/d" /etc/fstab
    oss=0
    nodeid=$n"01"
    
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
        /usr/local/sbin/yrfs-setup-storage -p /data/oss${oss} -S node${n}-stor -s $nodeid -i $oss_id -I tg$oss_id -z 0 -m $mgmthost -f
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
    
         /usr/local/sbin/yrfs-setup-meta -p /data/mds$mds -S node$n-stor -s $nodeid -m $mgmthost -f
         ((mds++))
    done
    systemctl daemon-reload;systemctl start yrfs-mgmtd;systemctl start yrfs-meta@mds0.service  yrfs-meta@mds1.service;systemctl start yrfs-storage;systemctl start yrfs-client
}

init(){
    yrcli --addgroup --type=mds --auto;yrcli --addgroup --type=oss --auto
    yrcli --mkfs
    yrcli --acl --op=add --path=/ --ip=* --mode=rw
    yrcli --cliacl --op=add --ip=*
    yrcli --setentry --stripesize=1m --schema=mirror --stripecount=4 / -u
}
rebuild $1 
#init
