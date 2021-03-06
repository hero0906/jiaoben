mount_dir=/mnt/yrfs
#client=(192.168.12.90 192.168.12.91 192.168.12.92 192.168.12.93 192.168.12.94 192.168.12.95 192.168.12.96 192.168.12.98)
<<<<<<< HEAD
client=(10.16.2.18)
=======
client=(10.16.2.17)
>>>>>>> 12789a73ab811c0446b7becfad7202f59866cf7a
#client=(192.168.12.90 192.168.12.91 192.168.12.92 192.168.12.93)
logs="/tmp/cy_test_logs"

findmnt $mount_dir 1> /dev/null
if [[ $? -ne 0 ]];then
    echo -e "\n \033[31m mount dir $mount_dir not exist! test quit!!! \033[0m\n"
    #exit
fi

FIO(){

    log_path="$logs/fio_run.log"
    path=$mount_dir"/fiotest/cy_fio_test_file"
    if [[ ! -d $path ]];then
        mkdir -p $path
    fi


    size=50M
    runtime=600
    RW=(write randwrite rw randrw)
    Numjobs=(1)
    Iodepth=(1 4 8 16)
    Ioengine=(sync psync libaio)
    Bs=(1K 3K 5K 16K 31K 101K 1025K 2049K 4097K)
    Direct=(0 1) 
    verifys=(md5 crc32 crc64 sha256 sha512)
    for rw in "${RW[@]}" ;do
        for numjobs in "${Numjobs[@]}";do
	        for ioengine in "${Ioengine[@]}";do 
		        for bs in "${Bs[@]}";do
                    for direct in "${Direct[@]}";do    
 			            for iodepth in "${Iodepth[@]}";do
                            for verify in "${verifys[@]}";do
                                testfile=$path"`uuidgen`"
	                            #config="fio -filename=$path -iodepth=$iodepth -direct=$direct -bs=$bs -size=$size --rw=${rw} -numjobs=${numjobs} -time_based -runtime=$runtime -ioengine=$ioengine -group_reporting -name=test -output=${log_path}${rw}${numjobs}${ioengine}${bs}${iodepth}${direct}${bs}"
	                            #config="fio -filename=$testfile -iodepth=$iodepth -direct=$direct -bs=$bs -size=$size --rw=${rw} -numjobs=${numjobs} -time_based -runtime=$runtime -ioengine=$ioengine -group_reporting -name=test -verify=crc64 --allrandrepeat=1"
                                config="fio -filename=$testfile -rw=$rw -ioengine=$ioengine -bs=$bs -size=$size -numjobs=$numjobs --iodepth=$iodepth --direct=$direct\
                                -runtime=$runtime -group_reporting -name=test -thread  -loops=1 -verify_backlog=10 -verify_dump=1 -continue_on_error=none -verify=$verify"

  			                    echo -e "[`date`]test running >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"|tee -a $log_path
  			                    echo -e "[`date`] $config"|tee -a $log_path
			                    $config 2>&1 |tee -a $log_path
			                    if [[ $? -ne 0 ]];then
			                        echo -e "`date` fio test run error"|tee -a $log_path
                                        exit
                                fi
                            done
			            done
                    done
                done
            done
        done
    done

}

vdbench(){

     rootdir=/home/vdbench
<<<<<<< HEAD
     files=1200
     size=2M
     bs=1M
     threads=8
     elapsed=1800
=======
     files=100
     size=200m
     bs=1M
     threads=8
     elapsed=72000
>>>>>>> 12789a73ab811c0446b7becfad7202f59866cf7a
     testdir=${mount_dir}/vdbench/`uuidgen`
     #testdir=${mount_dir}/vdbench/
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

     config3="fsd=fsd1,anchor=$testdir,depth=2,width=5,files=$files,size=$size,shared=yes
         \nfwd=format,threads=$threads,xfersize=$bs
         \nfwd=default,xfersize=$bs,fileio=random,fileselect=random,rdpct=50,threads=$threads\n"

     config4=""
     for hd in `seq $len`;do
         tmp="fwd=fwd$hd,fsd=fsd1,host=hd$hd"
         config4=$config4$tmp"\n"
     done

     config5="rd=rd1,fwd=fwd*,fwdrate=max,format=restart,elapsed=$elapsed,interval=5"

     config=$config1$config2$config3$config4$config5

     echo -e $config > vdbench_config
     ${rootdir}/vdbench  -f vdbench_config -o $logs/output.tod
     if [[ $? -ne 0 ]];then
         exit
     fi

#    /home/vdbench/vdbench -f 200m-demo-read -o 200m-demo-read-output

#    /home/vdbench/vdbench -f 200m-demo-write -o 200m-demo-write-output
}

MDtest(){

    nodes_file=nodeslist
    if [[ -e $nodes_file ]];then  
        > $nodes_file
    fi

    for ip in ${client[@]};do
        echo $ip >> $nodes_file
    done

    DEPTH=1
    WIDTH=10
    num_files=400000
    num_files_ls=200000
<<<<<<< HEAD
    loops=1
=======
    loops=900000
>>>>>>> 12789a73ab811c0446b7becfad7202f59866cf7a

    log_path=$logs/mdtest.log
    testdir="${mount_dir}/mdtest_client18/cy-mdtest-4y/`uuidgen`"
    testdir_ls="${mount_dir}/mdtest_client18/mdtest_ls_test/`uuidgen`"

    num_procs=`cat /proc/cpuinfo | grep "cpu cores" | uniq|awk '{print $4}'`

    files_per_dir=$(($num_files/$WIDTH/$num_procs))

    while true;do

	 if [[ -d $testdir ]];then
   	     rm -fr $testdir
             if [[ $? -ne 0 ]];then
		 echo -e "`date` remove $testdir failed"|tee -a $log_path
                 exit
             else
		 echo -e "`date` remove $testdir"|tee -a $log_path
             fi
         fi

   	 mkdir -p $testdir
         if [[ $? -ne 0 ]];then
	     echo -e "`date` mkdir $testdir failed"|tee -a $log_path
             exit
         else
	     echo -e "`date` mkdir $testdir"|tee -a $log_path
             
         fi

	 echo -e "`date` mdtest running."|tee -a $log_path
   	 #mpirun --allow-run-as-root --mca btl_tcp_if_include 192.145.12.0/24 -hostfile $nodes_file --map-by node -np ${num_procs} mdtest -C -d $testdir -i 1 \
   	 mpirun --allow-run-as-root --mca -hostfile $nodes_file --map-by node -np ${num_procs} mdtest -C -d $testdir -i 1 \
   	            -I ${files_per_dir} -z ${DEPTH} -b ${WIDTH} -i $loops -L -T  -F -u -w 0|tee -a $log_path

         if [[ $? -ne 0 ]];then
	     echo "`date` mpirun mdtest run error"|tee -a $log_path
             exit
         else
             echo "`date` mpirun mdtest run over"|tee -a $log_path
         fi

		
	 if [[ -d $testdir_ls ]];then
   	     rm -fr $testdir_ls
             if [[ $? -ne 0 ]];then
                 echo -e "`date` remove $testdir_ls failed"|tee -a $log_path
                 exit
             else
                 echo -e "`date` remove $testdir_ls"|tee -a $log_path
             fi
	 fi

   	 mkdir -p $testdir_ls
         if [[ $? -ne 0 ]];then
             echo -e "`date` mkdir $testdir_ls failed"|tee -a $log_path
             exit
         else
	     echo -e "`date` mkdir $testdir_ls"|tee -a $log_path
         fi
        

	 echo -e "`date` mdtest running"|tee -a $log_path
   	 mdtest -C -d $testdir_ls -i 1 -I $num_files_ls -z 1 -b 1 -L -T  -F -u -w 0|tee -a $log_path
         if [[ $? -ne 0 ]];then
             echo "`date` mpirun mdtest run error"|tee -a $log_path
             exit
         fi

	 echo -e "`date` ls $testdir_ls running."|tee -a $log_path
   	 (time ls -f -1 $testdir_ls | wc -l) 2>&1|tee -a $log_path
         if [[ $? -ne 0 ]];then
             echo "`date` ls $testdir_ls command run error"|tee -a $log_path
             exit
         fi

	 echo -e "`date` find $testdir_ls running."|tee -a $log_path
   	 (time find $testdir_ls | wc -l) 2>&1|tee -a $log_path
         if [[ $? -ne 0 ]];then
             echo "`date` find $testdir_ls command run error"|tee -a $log_path
             exit
         fi

    done

}

if [[ ! -d $logs ]];then
    mkdir $logs
fi

if [[ $# == 1 ]];then
    if [[ $1 == "mdtest" ]];then
        MDtest
    elif [[ $1 == "vdbench" ]];then
	    while true;do
            vdbench
	    done
    elif [[ $1 == "fio" ]];then
        while true;do
            FIO
        done
    else
        echo -e "paramter error!!!"
    fi
else
    echo -e "\033[35m \nUsage:\n
        $0 <mdtest|vdbench|fio>\n
	please input you want run test type:\n
	for example: $0 mdtest\n\033[0m"
fi
#while true;do
#    FIO
#done
#MDtest
