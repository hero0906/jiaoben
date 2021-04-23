#!/bin/bash

USER=root
PASSWORD="Passw0rd"
SSHP="sshpass -p $password ssh -o StrictHostKeyChecking=no"
LOG="logs/crash"_`date +%m%d%H%M`".log"
IPMI_USER="ADMIN"
IPMI_PASSWD="ADMIN"

STORAGE_PORT="ens2f0"
BUS_PORT="ens5f0"

ssh_no_key(){
    NET=$1
    if [[ ! -f ~/.ssh/id_rsa ]];then
        ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa &> /dev/null
    fi

    expect <<EOF
    spawn ssh-copy-id -i ${USER}@${NET}
        expect {
        "yes/no" { send "yes\r";exp_continue }
        "password:" { send "${PASSWORD}\r" }
        }
    expect eof
EOF
}

create_key(){

    yrcli --osd --type=mds
    if [[ $? != 0 ]];then
        log "this machine have no acl permission"
        exit
    fi
    ips=`yrcli --node --type=mgr|grep -v '<'|awk '{print $1}'`
    for ip in ips;do
        ssh_no_key $ip
    done

}


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

   start_mgr="systemctl restart yrfs-mgr"
   ips=`yrcli --node --type=mgr|grep -v "<"|awk '{print $1}'`

   while true;
   do
       status_mds=`yrcli --osd --type=mds|grep -v "up/clean"|awk 'NR>1'|wc -l`
       status_oss=`yrcli --osd --type=oss|grep -v "up/clean"|awk 'NR>1'|wc -l`
       status_mgrcmd="systemctl status yrfs-mgr.service |grep running|wc -l"
       status_mgr=0
       num_mgr=1

       for ip in $ips
       do

           while true;do
               status=`ssh $ip "$status_mgrcmd"`

               if [[ $status -ne 1 ]]
               then
		   log "$ip mgr service was down and trying reboot times: $num_mgr."
                   ssh -o ConnectTimeout=5 $ip "$start_mgr"
	       else
                   log "$ip mgr service status health."
		   break
               fi
	       ((num_mgr++))
	       Sleep 10
   	   done
           status_mgr=$((status_mgr+status))
       done

       #echo -e "`date` mds status $status_1,oss status $status_2"|tee -a $log
       if [[ $status_mds -ne 0 || $status_oss -ne 0 || $status_mgr -ne 3 ]]
       then
           log "cluster rebuilding,mds dirty: $status_mds,oss dirty: $status_oss,mgr offline: $((3-status_mgr))"
           Sleep 30
       else
           log "cluster present status record"
           date;yrcli --osd --type=mds |tee -a $LOG
           date;yrcli --osd --type=oss |tee -a $LOG
           date;yrcli --node --type=mgr |tee -a  $LOG
           for ip in $ips;do
	       log "$ip etcd service status:"
               ssh $ip systemctl status yrfs-mgr|grep Active 2>&1 |tee -a $LOG
               #ssh $ip etcdctl --endpoints=$ip:2379 endpoint health 2>&1 | tee -a $LOG
	       log "$ip mgr service status:"
               ssh $ip systemctl status yrfs-mgr|grep Active 2>&1 |tee -a $LOG
           done

           break
       fi
   done
}

kill_meta(){

   log "kill meta test running....."
   stop_meta="ps axu|grep -w yrfs-mds|grep -v grep|awk '{print \$2}'|xargs -I {} kill -9 {}"
   #start_meta="systemctl start yrfs-mds@mds0 yrfs-mds@mds1"
   start_meta="systemctl start yrfs-mds@mds0"
   #ips=`yrcli --osd --type=mds|grep master|awk '{print $2}'`

   if [[ $1 == 1 ]]
   then
       log "kill one mds running!"
       ips=`yrcli --osd --type=mds|grep master|awk '{print $2}'|uniq|shuf -n 1`
   elif [[ $1 == 2 ]]
   then
       #ips=`yrcli --osd --type=mds|grep master|awk '{print $2}'|uniq|shuf -n 2`
       log "kill two mds running!"
       ips=`yrcli --osd --type=mds|grep master|sort -k 4,4 -u|awk '{print $2}'|sort -u`
   else
       log "kill_meta parameter error test exit"
       exit
   fi

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

kill_mgr(){

   log "kill mgr test running....."

   stop_mgr="ps axu|grep yrfs-mgr|grep -v grep|awk '{print \$2}'|xargs kill -9"
   start_mgr="systemctl start yrfs-mgr"
   ip=`yrcli --node --type=mgr|grep -v "<"|grep master|awk '{print $1}'`

   log "mgr node $ip stop"

   ssh $ip $stop_mgr
   Sleep 30
   log "mgr node $ip start"
   ssh $ip $start_mgr
}

kill_oss(){

   log "kill oss test running......"
   stop_oss="ps axu|grep yrfs-oss|grep -v grep|awk '{print \$2}'|xargs kill -9"
   start_oss="systemctl start yrfs-oss"

   if [[ $1 == 1 ]]
   then
       ips=`yrcli --osd --type=oss|grep master|sort -k 4,4 -u|awk '{print $2}'|sort -u|shuf -n 1`
   elif [[ $1 == 2 ]]
   then
       ips=`yrcli --osd --type=oss|grep master|sort -k 4,4 -u|awk '{print $2}'|sort -u`
   else
       log "kill_oss test parameter error test exit"
       exit
   fi

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

down_oss_net(){

    log "down oss netcard test running......"
    random_ip=""
    }

crash_node(){

   log "crash node test running......"
   crash="echo \"c\" > /proc/sysrq-trigger"
   #ip=`yrcli --osd --type=mds|awk 'NR>=2{print $2}'|shuf -n 1|uniq`
   ips=`yrcli --node --type=mgr|grep -v "<"|grep master|awk '{print $1}'`
   #ips="$ip 172.17.74.78"
   #ssh -o ServerAliveInterval=2 $ip $crash
   for ip in $ips;do
       log "node $ip crashed"
       #ipmi_ip=$(ssh $ip ipmitool lan print|grep "IP Address"|awk -F ':' 'NR>1{print $2}')
       #ipmitool -H $ipmi_ip -U $IPMI_USER -P $IPMI_PASSWD power reset
       ssh -o ServerAliveInterval=2 $ip $crash
   done
   Sleep 30
}

down_mgr_net(){

    check_status

    log "down mgr netcard test running......"
    ip=`yrcli --node --type=mgr|grep -v "<"|grep master|awk '{print $1}'`
    bus_ip=$(ssh ${ip} "ifconfig $BUS_PORT|grep -w inet|awk '{print \$2}'")

    down_net="ifdown $STORAGE_PORT"
    up_net="ifup $STORAGE_PORT"

    log "mgr node $ip storage netcard down."
    ssh -o ServerAliveInterval=2 $bus_ip $down_net
    Sleep 30
    log "mgr node $ip storage netcard up."
    ssh $bus_ip $up_net

}


fsck_test(){

   log "cluster fsck test running."

   ips=`yrcli --osd --type=mds|awk 'NR>=2{print $2}'`
   #fsck="yrcli --fsck /data/mds --thread=8"
   #fsck="yrcli --fsck /data/mds0/replica  --cfg=/etc/yrfs/mds0.d/yrfs-mds.conf  --thread=8&&yrcli --fsck /data/mds1/replica  --cfg=/etc/yrfs/mds1.d/yrfs-mds.conf  --thread=8"
   fsck="yrcli --fsck /data/mds0/replica  --cfg=/etc/yrfs/mds0.d/yrfs-mds.conf  --thread=8"
   for ip in $ips;
   do
       log "node:$ip fsck running."
       ssh $ip $fsck 2>&1 | tee -a $log
   done
}


run(){

    time=1
    #fio init test data
    #./fio.sh run 2>&1 | tee -a $log
    while true;do
        #check_status
        log ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
        log "run test loops $time"
        log ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
        #cases=(kill_meta kill_mgr kill_oss crash_node)
        #cases=("kill_meta 1" kill_mgr "kill_oss 1" down_mgr_net)
        cases=(kill_mgr "kill_meta 2" "kill_oss 2")
	    for cas in "${cases[@]}";do
	        $cas
            #Sleep 3600
        done
        check_status
	    #wait
        ((time++))
    done
}
#fsck_test
run
#ssh_no_key
