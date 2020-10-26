log=$0`date +%m%d%H%M`".log"

fsck(){
    ips=`cat /etc/hosts|grep yanrong|awk '{print $1}'|grep -v 45.11`
    cmd="yrcli --fsck /data/mds0/replica  --cfg=/etc/yrfs/mds0.d/yrfs-meta.conf  --thread=8&&yrcli --fsck /data/mds1/replica  --cfg=/etc/yrfs/mds1.d/yrfs-meta.conf  --thread=8"
    for ip in $ips;do
        echo -e "`date` $ip run fsck"|tee -a $log
        ssh $ip $cmd |tee -a $log 
        #ssh $ip $cmd |tee -a $log &
    done
}

run(){
    nu=1
    while true;do
        echo -e "`date` bug 3695 test loop $nu"|tee -a $log
        echo -e "`date` dd file"|tee -a $log
        dd if=/dev/zero of=/mnt/yrfs/vdb_control.file bs=1M count=5 > $log 2>&1
    
        echo -e "`date` trunc run"|tee -a $log
        ./trunc > $log 2>&1
    
        fsck 
        echo -e "`date` rm file" |tee -a $log
        rm -fr /mnt/yrfs/vdb_control.file
        ((nu++))
    done
}
run
