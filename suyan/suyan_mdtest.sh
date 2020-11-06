#!/bin/bash
 
#nodes_file=./nodelist
 
DEPTH=4
WIDTH=10
#num_files=3000000
#文件总数计算方式width的depth次幂，乘以num_files乘以np数量

num_files=10000
 
log="suyan_mdtest.log"
#dir=/mnt/yrfs/test/quota001/mdtest/`uuidgen`
#mpirun --allow-run-as-root --mca btl_tcp_if_include 19.45.12.0/24 -hostfile $nodes_file \
#--map-by node -np 2 mdtest -C -d $dir -i 1 -I ${files_per_dir} -z ${DEPTH} -b ${WIDTH} -L -T  -F -u

#测试create 和 stat性能


for num in `seq 1 8`;do

#    echo -e "`date` loops $num test mdtest perfomence test" |tee -a $log 
#    dir=/mnt/yrfs/mdtest/test_suyan$num
#    mkdir -p $dir
#    mpirun --allow-run-as-root -np 4 mdtest -C -F -L -z 1 -b 10 -I 1000 -d $dir -T |tee -a $log

    echo -e "`date` loops $num test mdtest fill data" |tee -a $log 
    dir=/mnt/yrfs/mdtest/fill_suyan_two_$num
    mkdir -p $dir
    mpirun --allow-run-as-root -np 4 mdtest -C -F -L -z $DEPTH -b $WIDTH -I $num_files -d $dir |tee -a $log

done

#echo -e "`date` last loops test mdtest perfomence test" |tee -a $log                                                                                                                                    
#dir=/mnt/yrfs/mdtest/test_suyanlast                                                                                                                                                                     
#mkdir -p $dir                                                                                                                                                                                               
#mpirun --allow-run-as-root -np 4 mdtest -C -F -L -z 1 -b 10 -I 1000 -d $dir -T |tee -a $log
#
#echo -e '`date` 365 ls test 200w file create'|tee -a $log
#dir=/mnt/yrfs/mdtest/test_suyan_ls
#mkdir -p $dir
#mpirun --allow-run-as-root -np 4 mdtest -C -F -L -z 1 -b 1 -I 500000 -d $dir |tee -a $log
#
#echo -e "ls dir test"|tee -a $log
#date|tee -a $log
#(time ls -f -l $dir |wc -l) 2>&1|tee -a $log
#date|tee -a $log
#
#echo -e "find dir test"|tee -a $log
#date|tee -a $log
#(time find $dir|wc -l) 2>&1|tee -a $log
#date|tee -a $log
