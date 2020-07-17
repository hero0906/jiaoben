# Sleep seconds
Sleep(){
    echo -n "Sleep total second ${1}s :"
    tput sc
    count=0
    while true;
    do
         if [[ $count -lt $1 ]];then
                 let count++;
                 sleep 1;
                 tput rc
                 tput ed
                 echo -n "${count}s";
         else
                 break
         fi
    done
}

build_status(){
    while true;
    do
	status=`yrcli --osd --type=oss|grep "rebuild"|wc -l`
	#status="0"
	if [[ $status != 0 ]]
	then
	    Sleep 5
	    echo -e "\noss status rebuilding"
	    continue
	else
	    break
	fi
    done
}

run(){
    crash="echo \"c\" > /proc/sysrq-trigger"
    time=1
    while true;do
        build_status
        echo -e "run test loops $time"|tee -a crash.log
        master=`yrcli --node --type=mgmt|grep master|awk {'print $1'}`
        if ping -c 1 $master >/dev/null;then
            echo "$master Ping is success"|tee -a crash.log 
            echo -e "$master $crash running"|tee -a crash.log
            ssh -o ServerAliveInterval=2 $master $crash 
	    Sleep 10
            echo -e "$master crashed"|tee -a crash.log
            ((time++))
       else
            echo "ip no connetions"
            exit -1
       fi
    done 
}
run
