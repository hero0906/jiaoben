FIO(){
    size=50G
    runtime=60
    path=/mnt/client/1.file
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
            -time_based -runtime=$runtime -ioengine=psync -group_reporting -name=test -output=output/512K_${rw}_jobs_${numjobs}
        done
    done

}

vdbench(){ 

     files=100
     size="64KB"
     threads=16
     elapsed=600

     config="
         messagescan=no
         \nhd=default,vdbench=/home/vdbench,user=root,shell=ssh
         \nhd=hd1,system=c1
         \nhd=hd2,system=c2
         \nfsd=fsd1,anchor=/mnt/client/test64KB,depth=1,width=10,openflag=o_direct,files=$files,size=$size,shared=yes
         \nfwd=format,threads=$threads,xfersize=32k
         \nfwd=default,xfersize=32k,fileio=random,fileselect=random,rdpct=60,threads=$threads
         \nfwd=fwd1,fsd=fsd1,host=hd1
         \nfwd=fwd2,fsd=fsd1,host=hd2
         rd=rd1,fwd=fwd*,fwdrate=max,format=restart,elapsed=$elapsed,interval=1"

     echo -e $config > 64k-demo
# echo -e $config >> 64k-demo 
     /home/vdbench/vdbench  -f 64k-demo -o output.tod

#    /home/vdbench/vdbench -f 200m-demo-read -o 200m-demo-read-output

#    /home/vdbench/vdbench -f 200m-demo-write -o 200m-demo-write-output
}

MDtest(){
    nodes_file=./nodeslist
    DEPTH=1
    WIDTH=10
    num_files=400000
    log_path=output/mdtest.log
 
    rm -fr /mnt/client/mdtest-4y
    mkdir -p /mnt/client/mdtest-4y   

    for num_procs in "4"; do
       files_per_dir=$(($num_files/$WIDTH/$num_procs))
       mpirun --allow-run-as-root --mca btl_tcp_if_include 172.17.0.0/16 -hostfile $nodes_file --map-by node -np ${num_procs} mdtest -C -d /mnt/client/mdtest-4y -i 1 \
	       -I ${files_per_dir} -z ${DEPTH} -b ${WIDTH} -L -T  -F -u -w 0 |tee -a $log_path
    done
    
    rm -fr /mnt/client/abc
    mkdir -p mkdir /mnt/client/abc
    date;mdtest -C -d /mnt/client/abc/ -i 1 -I 200000 -z 1 -b 1 -L -T  -F -u -w 0|tee -a tee -a $log_path
    
    date;(time ls -f -1 /mnt/client/abc | wc -l) 2>&1|tee -a $log_path
    date;(time find /mnt/client/abc/ | wc -l) 2>&1|tee -a $log_path
    
}

FIO
vdbench
MDtest
