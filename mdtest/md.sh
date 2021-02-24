#!/bin/bash
 
nodes_file=./nodelist
 
DEPTH=0
WIDTH=0
num_files=100
num_procs_array=4
files_per_dir=5000
 
#dir=/mnt/yrfs/test/quota001/mdtest/`uuidgen`
#mpirun --allow-run-as-root --mca btl_tcp_if_include 19.45.12.0/24 -hostfile $nodes_file \
#--map-by node -np 2 mdtest -C -d $dir -i 1 -I ${files_per_dir} -z ${DEPTH} -b ${WIDTH} -L -T  -F -u

for num in `seq 1`;do
    dir=/mnt/yrfs/B/`uuidgen`
    mkdir -p $dir
    #mdtest -C -d $dir -i 1 -I $num_files -z ${DEPTH} -b ${WIDTH} -T -F -u
    mdtest -C -d $dir -I $num_files -F
done
    #mdtest -C -d /mnt/yrfs/test/quota002/test4 -i 1 -I $num_files -z ${DEPTH} -b ${WIDTH} -T  -F -u &
   #ior -C -d /mnt/yrfs/test/quota002 -i 1 -I ${files_per_dir} -z ${DEPTH} -b ${WIDTH} -L -T  -F -u
