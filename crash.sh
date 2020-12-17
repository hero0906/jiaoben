#!/bin/bash

USER=root
PASSWORD="Passw0rd"
SSHP="sshpass -p $password ssh -o StrictHostKeyChecking=no"
LOG="logs/crash"_`date +%m%d%H%M`".log"
IPMI_USER="ADMIN"
IPMI_PASSWD="ADMIN"

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

create_test_env(){
    yrcli --osd --type=mds
    if [[ $? != 0 ]];then
        log "this machine have no acl permission"
        exit
    fi
    ips=`yrcli --node --type=mgmt|awk '{print $1}'`
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

   start_mgmt="systemctl restart yrfs-mgmtd"
   ips=`yrcli --node --type=mgmt|awk '{print $1}'`

   while true;
   do
       status_mds=`yrcli --osd --type=mds|grep -v "up/clean"|awk 'NR>1'|wc -l`
       status_oss=`yrcli --osd --type=oss|grep -v "up/clean"|awk 'NR>1'|wc -l`
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
       else
           log "cluster present status record"
           date;yrcli --osd --type=mds |tee -a $LOG
           date;yrcli --osd --type=oss |tee -a $LOG
           date;yrcli --node --type=mgmt |tee -a  $LOG
           for ip in `yrcli --node --type=mgmt|awk '{print $1}'`;do
	       log "$ip etcd service status:"
               ssh $ip systemctl status yrfs-mgmtd|grep Active 2>&1 |tee -a $LOG
               #ssh $ip etcdctl --endpoints=$ip:2379 endpoint health 2>&1 | tee -a $LOG
	       log "$ip mgmtd service status:"
               ssh $ip systemctl status yrfs-mgmtd|grep Active 2>&1 |tee -a $LOG
           done

           break
       fi
   done
}

kill_meta(){

   log "kill meta test running....."
   stop_meta="ps axu|grep -w yrfs-meta|grep -v grep|awk '{print \$2}'|xargs -I {} kill -9 {}"
   #start_meta="systemctl start yrfs-meta@mds0 yrfs-meta@mds1"
   start_meta="systemctl start yrfs-meta@mds0"
   #ips=`yrcli --osd --type=mds|grep master|awk '{print $2}'`

   if [[ $1 == 1 ]]
   then
       ips=`yrcli --osd --type=mds|grep master|awk '{print $2}'|uniq|shuf -n 1`
   elif [[ $1 == 2 ]]
   then
       #ips=`yrcli --osd --type=mds|grep master|awk '{print $2}'|uniq|shuf -n 2`
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

kill_mgmt(){

   log "kill mgmt test running....."

   stop_mgmt="ps axu|grep yrfs-mgmtd|grep -v grep|awk '{print \$2}'|xargs kill -9"
   start_mgmt="systemctl start yrfs-mgmtd"
   ip=`yrcli --node --type=mgmt|grep master|awk '{print $1}'`

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
   ips=`yrcli --node --type=mgmt|grep master|awk '{print $1}'`
   #ips="$ip 172.17.74.78"
   #ssh -o ServerAliveInterval=2 $ip $crash
   for ip in $ips;do
       log "node $ip crashed"
       ipmi_ip=$(ssh $ip ipmitool lan print|grep "IP Address"|awk -F ':' 'NR>1{print $2}')
       ipmitool -H $ipmi_ip -U $IPMI_USER -P $IPMI_PASSWD power reset
       #ssh -o ServerAliveInterval=2 $ip $crash
   done
   Sleep 30

}


fsck_test(){

   log "cluster fsck test running."

   ips=`yrcli --osd --type=mds|awk 'NR>=2{print $2}'`
   #fsck="yrcli --fsck /data/mds --thread=8"
   fsck="yrcli --fsck /data/mds0/replica  --cfg=/etc/yrfs/mds0.d/yrfs-meta.conf  --thread=8&&yrcli --fsck /data/mds1/replica  --cfg=/etc/yrfs/mds1.d/yrfs-meta.conf  --thread=8"
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
        #cases=(kill_meta kill_mgmt kill_oss crash_node)
        cases=("kill_meta 2" kill_mgmt "kill_oss 2")
	    for cas in "${cases[@]}";do
            check_status
	        $cas
            #Sleep 3600
        done
	    #wait
        ((time++))
    done
}
#fsck_test
run
#ssh_no_key
