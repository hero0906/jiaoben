mount_dir=/mnt/yrfs2
client=(192.168.48.12)
logs="logs"
#client=(192.168.48.17)
#client2=192.168.48.18

findmnt $mount_dir 2>&1 /dev/null
echo $?
if [[ $? != 0 ]];then
    echo -e "\n \033[31m mount dir $mount_dir not exist! test quit!!! \033[0m\n"
    exit
fi

FIO(){

    log_path="$logs/fio_run.log"
    path=$mount_dir"/cy_fio_test_file"

    size=500G
    runtime=60
    RW=(write read randwrite randread rw randrw)
    Numjobs=(1 4 8 16)
    Iodepth=(1 4 8 16)
    Ioengine=(sync psync libaio)
    Bs=(4K)
    Direct=(0 1) 
    for rw in "${RW[@]}" ;do
        for numjobs in "${Numjobs[@]}";do
	    for ioengine in "${Ioengine[@]}";do 
		for bs in "${Bs[@]}";do
                    for direct in "${Direct[@]}";do    
 			for iodepth in "${Iodepth[@]}";do
	                    #config="fio -filename=$path -iodepth=$iodepth -direct=$direct -bs=$bs -size=$size --rw=${rw} -numjobs=${numjobs} -time_based -runtime=$runtime -ioengine=$ioengine -group_reporting -name=test -output=${log_path}${rw}${numjobs}${ioengine}${bs}${iodepth}${direct}${bs}"
	                    config="fio -filename=$path -iodepth=$iodepth -direct=$direct -bs=$bs -size=$size --rw=${rw} -numjobs=${numjobs} -time_based -runtime=$runtime -ioengine=$ioengine -group_reporting -name=test"
  			    echo -e "[`date`]test running >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"|tee -a $log_path
  			    echo -e $config|tee -a $log_path
			    $config 2>&1 |tee -a $log_path
			done
                    done
                done
            done
        done
     done

#    for rw in read write;do
#        for numjobs in 4 8 16;do
#	    fio -filename=$path -iodepth=1 -direct=0 -bs=512K -size=$size --rw=${rw} -numjobs=${numjobs} \
#            -time_based -runtime=$runtime -ioengine=psync -group_reporting -name=test -output=${log_path}512K_${rw}_jobs_${numjobs}
#        done
#    done

}

vdbench(){

     rootdir=/home/vdbench
     files=10000
     size=400K
     bs=4k
     threads=32
     elapsed=6000000
     testdir=${mount_dir}/vdbench/`uuidgen`
     len=${#client[@]}
     
     if [[ ! -d $testdir ]];then 
         mkdir -p $testdir
     fi

     config1="
         messagescan=no
         \nhd=default,vdbench=$rootdir,user=root,shell=ssh\n"

     config2=""
     for hd in `seq $len`;do
         tmp="hd=hd$hd,system=${client[(($hd-1))]}"
         config2=$config2$tmp"\n"
     done

     config3="fsd=fsd1,anchor=$testdir,depth=4,width=5,files=$files,size=$size,shared=yes
         \nfwd=format,threads=$threads,xfersize=$bs
         \nfwd=default,xfersize=$bs,fileio=random,fileselect=random,rdpct=0,threads=$threads\n"

     config4=""
     for hd in `seq $len`;do
         tmp="fwd=fwd$hd,fsd=fsd1,host=hd$hd"
         config4=$config4$tmp"\n"
     done

     config5="rd=rd1,fwd=fwd*,fwdrate=max,format=restart,elapsed=$elapsed,interval=5"

     config=$config1$config2$config3$config4$config5

     echo -e $config > vdbench_config
     ${rootdir}/vdbench  -f vdbench_config -o $logs/output.tod

#    /home/vdbench/vdbench -f 200m-demo-read -o 200m-demo-read-output

#    /home/vdbench/vdbench -f 200m-demo-write -o 200m-demo-write-output
}

MDtest(){

    nodes_file=nodeslist

    for ip in ${client[@]};do
        echo $ip > $nodes_file
    done

#    echo $client2 >> $nodes_file
    DEPTH=1
    WIDTH=10
    num_files=400000
    log_path=output/mdtest.log

    rm -fr $mount_dir/mdtest-4y
    mkdir -p $mount_dir/mdtest-4y

    num_procs=`cat /proc/cpuinfo | grep "cpu cores" | uniq|awk '{print $4}'`

    files_per_dir=$(($num_files/$WIDTH/$num_procs))
    mpirun --allow-run-as-root --mca btl_tcp_if_include 172.17.0.0/16 -hostfile $nodes_file --map-by node -np ${num_procs} mdtest -C -d $mount_dir/mdtest-4y -i 1 \
	       -I ${files_per_dir} -z ${DEPTH} -b ${WIDTH} -L -T  -F -u -w 0 |tee -a $log_path

    rm -fr $mount_dir/abc
    mkdir -p mkdir $mount_dir/abc
    date;mdtest -C -d $mount_dir/abc/ -i 1 -I 200000 -z 1 -b 1 -L -T  -F -u -w 0|tee -a tee -a $log_path

    date;(time ls -f -1 $mount_dir/abc | wc -l) 2>&1|tee -a $log_path
    date;(time find $mount_dir/abc/ | wc -l) 2>&1|tee -a $log_path

}

if [[ ! -d "logs" ]];then
    mkdir logs
fi

if [[ $# == 1 ]];then
    if [[ $1 == "mdtest" ]];then
        MDtest
    elif [[ $1 == "vdbench" ]];then
        vdbench
    elif [[ $1 == "fio" ]];then
        FIO
    fi
else
    echo -e "Usage $0 <mdtest|vdbench|fio>\n"
fi
#while true;do
#    FIO
#done
#MDtest
