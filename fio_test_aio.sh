#cache=`cat /etc/yrfs/yrfs-client.conf|grep client_cache_type|grep -v "#"|awk  -F '=' '{print $2}'`
cache=`cat /etc/yrfs/yrfs-client.conf|grep client_cache_type|grep -v "#"|awk  -F '=' '{print $2}' |awk '{gsub(/^\s+|\s+$/, "");print}'`
version=`rpm -qa|grep yrfs-client|awk -F '-' '{print $3}'`
filename="/mnt/yrfs/file_test001"

drop_cache='sync&&echo 3 >/proc/sys/vm/drop_caches'
direct=0

logs="/tmp/aio_test_${version}"

if [[ ! -d $logs ]];then
    echo -e "mkdir $logs"
    mkdir $logs
fi

set_mode(){
    mode=$1
    echo -e "sed cache mode: $mode"
    sed -i "s/^client_cache_type.*/client_cache_type                 = $mode/" /etc/yrfs/yrfs-client.conf
}

runtime=600

iops(){
    directs=(0 1)
    rws=("randwrite" "randread")
    bss=("4k 16k")
    iodepths=(1 4 8 16 32 64 128)
    numjobs=(1)

    eval $drop_cache
 
    for direct in ${directs[@]};do
        for rw in ${rws[@]};do
            for bs in ${bss[@]};do
                for numjob in ${numjobs[@]};do
               	    for iodepth in ${iodepths[@]};do
               	           output=${logs}/"iops_"$cache"_direct"$direct"_"$rw"_"$bs"_numjob"$numjob"_iodepth"$iodepth
               	           fio="fio -ioengine=libaio -direct=$direct -ramp_time=10 -group_reporting -size=100G -runtime=$runtime -time_based -numjobs=$numjob -iodepth=$iodepth -name=$rw$bs -filename=$filename -rw=$rw -bs=$bs -output=$output"
               	           echo -e "\033[35m `date` | $fio running!!!\033[0m"
               	           $fio
               	           echo -e "\033[35m `date` | drop cache\033[0m"
               	           eval $drop_cache
               	   	done
                done
            done
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
iops
