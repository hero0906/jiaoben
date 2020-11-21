#!/bin/bash

PASSWORD="Passw0rd"
SSHP="sshpass -p $password ssh -o StrictHostKeyChecking=no"
LOG="logs/crash"_`date +%m%d%H%M`".log"

if [[ ! -d "logs" ]];then
    mkdir logs
fi

log(){
    echo -e "`date "+%Y-%m-%d %H:%M:%S"`: $1" | tee -a $LOG        
}

Sleep(){
    echo -n "Sleep ${1}s:" | tee -a $LOG
    tput sc
    count=0
    while true;
    do
         if [[ $count -lt $1 ]];then
                 ((count++))
                 sleep 1
		 tput civis
                 tput rc
                 tput ed
                 echo -n "${count}s"
         else
                 break
         fi
    done
    echo | tee -a $LOG
}


check_status(){

   start_mgmt="systemctl restart yrfs-mgmtd"
   ips=`yrfs-ctl --listnodes --nodetype=mgmt|awk '{print $1}'`

   stat_nu=1

   while true;
   do
       #status_mds=`yrcli --osd --type=mds|grep -v "up/clean"|awk 'NR>1'|wc -l`
       status_mds=`yrfs-ctl --listtargets --nodetype=meta --state|awk 'NR>2'|grep "Online"|grep -v "Good"|wc -l`

       #status_oss=`yrcli --osd --type=oss|grep -v "up/clean"|awk 'NR>1'|wc -l`
       status_oss=`yrfs-ctl --listtargets --nodetype=storage --state|awk 'NR>2'|grep -v "Online"|grep -v "Good"|wc -l`

       status_mgmtcmd="systemctl status yrfs-mgmtd.service |grep running|wc -l"
       status_mgmt=0
       num_mgmt=1

       for ip in $ips
       do

           while true;do
               status=`ssh $ip "$status_mgmtcmd"`

               if [[ $status -ne 1 ]]
               then
		   log "$ip mgmt service was down and trying reboot times: $num_mgmt."
                   ssh -o ConnectTimeout=5 $ip "$start_mgmt"
	       else
                   log "$ip mgmt service status health."
		   break
               fi
	       ((num_mgmt++))
	       Sleep 10
   	   done
           status_mgmt=$((status_mgmt+status))
       done

       #echo -e "`date` mds status $status_1,oss status $status_2"|tee -a $log
       if [[ $status_mds -ne 0 || $status_oss -ne 0 || $status_mgmt -ne 3 ]]
       then
           log "cluster rebuilding,mds dirty: $status_mds,oss dirty: $status_oss,mgmt offline: $((3-status_mgmt))"
           Sleep 30
           log "cluster check health times: $stat_nu"
           ((stat_nu++))
       else
           log "check cluster status health test runing!!!"
           date;yrfs-ctl --listtargets --nodetype=meta --state |tee -a $LOG
           date;yrfs-ctl --listtargets --nodetype=storage --state |tee -a $LOG
           date;yrfs-ctl --listnodes --nodetype=mgmt|tee -a  $LOG
           for ip in $ips;do
	       log "$ip etcd service status:"
               ssh $ip etcdctl --endpoints=$ip:2379 endpoint health 2>&1 | tee -a $LOG
	       log "$ip mgmtd service status:"
               ssh $ip systemctl status yrfs-mgmtd|grep Active 2>&1 |tee -a $LOG
           done
           echo

           break
       fi
   done
}

kill_meta(){

   log "kill meta test running....."
   stop_meta="ps axu|grep -w yrfs-meta|grep -v grep|awk '{print \$2}'|xargs -I {} kill -9 {}"
   #start_meta="systemctl start yrfs-meta@mds0 yrfs-meta@mds1"
   start_meta="systemctl start yrfs-meta"
   #ips=`yrcli --osd --type=mds|grep master|awk '{print $2}'`

  # if [[ $1 == 1 ]]
  # then
  #     ips=`yrcli --osd --type=mds|grep master|awk '{print $2}'|uniq|shuf -n 1`
  # elif [[ $1 == 2 ]]
  # then
  #     #ips=`yrcli --osd --type=mds|grep master|awk '{print $2}'|uniq|shuf -n 2` 
  #     ips=`yrcli --osd --type=mds|grep master|sort -k 4,4 -u|awk '{print $2}'|sort -u`
  # else
  #     log "kill_meta parameter error test exit"
  #     exit
  # fi
   ips=`yrfs-ctl --listnodes --nodetype=mgmt|shuf -n 1|awk '{print $1}'|uniq`

   for ip in $ips;do
       log "mds node $ip stop"
       ssh $ip $stop_meta 
   done
   Sleep 30 
   for ip in $ips;do
       log "mds node $ip start"
       ssh $ip $start_meta
   done

}

kill_mgmt(){

   log "kill mgmt test running....."

   stop_mgmt="ps axu|grep yrfs-mgmtd|grep -v grep|awk '{print \$2}'|xargs kill -9" 
   start_mgmt="systemctl start yrfs-mgmtd"
   #ip=`yrcli --node --type=mgmt|grep master|awk '{print $1}'`
   ip=`yrfs-ctl --listnodes --nodetype=mgmt|grep master|awk '{print $1}'`

   log "mgmt node $ip stop"

   ssh $ip $stop_mgmt  
   Sleep 30
   log "mgmt node $ip start"
   ssh $ip $start_mgmt 
}

kill_oss(){

   log "kill oss test running......"
   stop_oss="ps axu|grep yrfs-storage|grep -v grep|awk '{print \$2}'|xargs kill -9"
   start_oss="systemctl start yrfs-storage"

  # if [[ $1 == 1 ]]
  # then
  #     ips=`yrcli --osd --type=oss|grep master|sort -k 4,4 -u|awk '{print $2}'|sort -u|shuf -n 1` 
  # elif [[ $1 == 2 ]]
  # then
  #     ips=`yrcli --osd --type=oss|grep master|sort -k 4,4 -u|awk '{print $2}'|sort -u`
  # else
  #     log "kill_oss test parameter error test exit"
  #     exit
  # fi
  ips=`yrfs-ctl --listnodes --nodetype=mgmt|shuf -n 1|awk '{print $1}'|uniq`

   for ip in $ips;do
       log "oss node $ip stop"
       ssh $ip $stop_oss
   done

   Sleep 30

   for ip in $ips;do
       log "oss node $ip start"
       ssh $ip $start_oss
   done

}

crash_node(){

   log "crash node test running......"
   crash="echo \"c\" > /proc/sysrq-trigger"  
   #ip=`yrcli --osd --type=mds|awk 'NR>=2{print $2}'|shuf -n 1|uniq`
   ips=`yrfs-ctl --listnodes --nodetype=mgmt|grep master|awk '{print $1}'`
   #ips="$ip 172.17.74.78"
   #ssh -o ServerAliveInterval=2 $ip $crash
   for ip in $ips;do
       log "node $ip crashed"
       ssh -o ServerAliveInterval=2 $ip reboot
   done
   Sleep 60

}


fsck_test(){

   log "cluster fsck test running."

   ips=`yrcli --osd --type=mds|awk 'NR>=2{print $2}'`
   fsck="yrcli --fsck /data/mds --thread=32"
   for ip in $ips;
   do
       log "node:$ip fsck running."
       ssh $ip $fsck 2>&1 | tee -a $log 
   done
}    

fio_test(){

    dirs=""
    for((n=1;n<16;n++));do
        dir=/mnt/yrfs/qos/test_qos00$n
	mkdir -p $dir
        dirs=$dirs$dir":"
    done

    seed=$(echo $RANDOM)
    rw="write"
    rand_distribution=random:1/zipf:4/pareto:2/normal:1/zoned:1/zoned_abs:1
    rand_gener=(tausworthe lfsr tausworthe64 tausworthe)
    sync=1
    ioengine=(sync psync vsync pvsync pvsync2 io_uring rdma posixaio)
    verify=(md5 crc64 crc32c crc32 crc16 crc7 sha256 )
    numjobs=1
    #dirs="/tmp"
    output="logs/fio_"`date +%H:%M_%m-%d`".log"
    log "fio tes funning"
    fio_run="fio \
    --group_reporting \
    --ioengine=psync \
    --directory=$dirs \
    --name=test \
    --bs=4K \
    --numjobs=$numjobs \
    --size=50M \
    --nrfiles=160
    --rw=$rw \
    --verify=crc64 \
    --loops=1 \
    --allrandrepeat=1 \
    --continue_on_error=verify \
    --random_distribution=$rand_distribution \
    --random_generator=${rand_gener[2]} \
    "
    $fio_run 2>&1 |tee -a $LOG
}

run(){

    time=1
    #fio init test data
    #./fio.sh run 2>&1 | tee -a $log 
    while true;do
        log ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
        log "run test loops $time!!!!!!"
        log ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
        check_status
        #cases=(kill_meta kill_mgmt kill_oss crash_node)
        cases=(kill_mgmt kill_oss kill_meta)
        #cases=("kill_meta 2" kill_mgmt "kill_oss 1")
	for cas in "${cases[@]}";do
	    $cas & 
        done
        Sleep 30
	wait
        #fio_test
        ((time++))
    done 
}

run
