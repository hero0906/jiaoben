mount_dir=/mnt/yrfs3
client=(192.168.48.17 192.168.48.18)
#client=(192.168.48.17)
#client2=192.168.48.18

FIO(){

    size=50G
    runtime=6000
    path=$mount_dir"/1.file"
    log_path="output/"`date +%m%d%H%M`"_"
    for rw in randread randwrite;do
        for numjobs in 4 8 16;do
	    fio -filename=$path -iodepth=1 -direct=0 -bs=4K -size=$size --rw=${rw} -numjobs=${numjobs} \
	     -time_based -runtime=$runtime -ioengine=psync -group_reporting -name=test -output=${log_path}4K_${rw}_jobs_${numjobs}
        done
     done

    for rw in read write;do
        for numjobs in 4 8 16;do
	    fio -filename=$path -iodepth=1 -direct=0 -bs=512K -size=$size --rw=${rw} -numjobs=${numjobs} \
            -time_based -runtime=$runtime -ioengine=psync -group_reporting -name=test -output=${log_path}512K_${rw}_jobs_${numjobs}
        done
    done

}

vdbench(){

     rootdir=/home/vdbench
     files=100000
     size="64KB"
     threads=8
     elapsed=6000000
     len=${#client[@]}
     config1="
         messagescan=no
         \nhd=default,vdbench=$rootdir,user=root,shell=ssh\n"

     config2=""
     for hd in `seq $len`;do
         tmp="hd=hd$hd,system=${client[(($hd-1))]}"
         config2=$config2$tmp"\n"
     done

     config3="fsd=fsd1,anchor=$mount_dir/test64KB,depth=1,width=10,openflag=o_direct,files=$files,size=$size,shared=yes
         \nfwd=format,threads=$threads,xfersize=32k
         \nfwd=default,xfersize=32k,fileio=random,fileselect=random,rdpct=60,threads=$threads\n"

     config4=""
     for hd in `seq $len`;do
         tmp="fwd=fwd$hd,fsd=fsd1,host=hd$hd"
         config4=$config4$tmp"\n"
     done

     config5="rd=rd1,fwd=fwd*,fwdrate=max,format=restart,elapsed=$elapsed,interval=1"

     config=$config1$config2$config3$config4$config5

     echo -e $config > 64k-demo
     ${rootdir}/vdbench  -f 64k-demo -o output/output.tod

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

if [[ ! -d "output" ]];then
    mkdir output
fi

#FIO
vdbench
#MDtest
