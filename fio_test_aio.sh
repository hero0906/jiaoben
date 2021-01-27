#cache=`cat /etc/yrfs/yrfs-client.conf|grep client_cache_type|grep -v "#"|awk  -F '=' '{print $2}'`
cache=`cat /etc/yrfs/yrfs-client.conf|grep client_cache_type|grep -v "#"|awk  -F '=' '{print $2}' |awk '{gsub(/^\s+|\s+$/, "");print}'`
version=`rpm -qa|grep yrfs-client|awk -F '-' '{print $3}'`


drop_cache='sync&&echo 3 >/proc/sys/vm/drop_caches'
direct=0

logs="/tmp/aio_test_direct${direct}_${version}"

if [[ ! -d $logs ]];then
    echo -e "mkdir $logs"
    mkdir $logs
fi

iops(){
    rws=("randwrite" "randread")
    bss=("4k 16k")
    iodepth=64
    runtime=300
    for rw in ${rws[@]};do
        for bs in ${bss[@]};do
            output=${logs}/"iops_"$cache$rw$bs
            fio="fio -ioengine=libaio -direct=$direct -ramp_time=10 -group_reporting -size=50G -runtime=$runtime -time_based -numjobs=1 -iodepth=$iodepth -eta-newline=1 -name=$rw$bs -filename=/mnt/yrfs/file_test001 -rw=$rw -bs=$bs -output=$output"
	    echo -e "\033[35m `date` | $fio running!!!\033[0m"
	    $fio
            echo -e "\033[35m `date` | drop cache\033[0m"
            eval $drop_cache
        done
    done
}

bw(){
    rws=("write" "read")
    bss=("4m 64m")
    iodepth=64
    runtime=300
    for rw in ${rws[@]};do
        for bs in ${bss[@]};do
            output=${logs}/"bw_"$cache$rw$bs
            fio="fio -ioengine=libaio -direct=$direct -ramp_time=10 -group_reporting -size=50G -runtime=$runtime -time_based -numjobs=1 -iodepth=$iodepth -eta-newline=1 -name=$rw$bs -filename=/mnt/yrfs/file_test001 -rw=$rw -bs=$bs -output=$output"
	    echo -e "\033[35m `date` | $fio running!!!\033[0m"
	    $fio
            echo -e "\033[35m `date` | drop cache\033[0m"
            eval $drop_cache
    	done
    done
}

verify(){
    filename=/mnt/yrfs/fio_verify_file001
    logs="/tmp/fio_verify.log"
    while true;do
        bs=$(echo $RANDOM)"K"
        fio="fio -filename=$filename -rw=randrw -eta-newline=2 -bs=$bs -bsrange=1k-512k,1k-512k -ioengine=libaio -verify_backlog=10  -verify_dump=1 -iodepth=128 -numjobs=1 -size=800M -group_reporting -name=seq_write_first -direct=1 -thread -verify=crc64"
        echo -e "\033[35m`date`\t | \t $fio running\033[0m"|tee -a $logs
        $fio|tee -a $logs
        if [[ $? -ne 0 ]];then
            echo -e "\033[31m `date`\t|\t $fio run failed\033[0m"
            exit
        fi

        fio="fio -filename=$filename -rw=randrw -eta-newline=2 -bs=$bs -bsrange=1M-16M,1M-16M -ioengine=libaio -verify_backlog=10  -verify_dump=1 -iodepth=128 -numjobs=1 -size=800M -group_reporting -name=seq_write_first -direct=1 -thread -verify=crc64"
        echo -e "\033[35m`date`\t | \t $fio running\033[0m"|tee -a $logs
        $fio|tee -a $logs
        if [[ $? -ne 0 ]];then
            echo -e "\033[31m `date`\t|\t $fio run failed\033[0m"
            exit
        fi
    done
}
#verify
#iops
bw
