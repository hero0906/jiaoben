#!/bin/bash
 
nodes_file=./nodeslist
 
DEPTH=1
WIDTH=10
num_files=40
 
for num_procs in "2"; do
   files_per_dir=$(($num_files/100/$num_procs))
   mpirun --allow-run-as-root --mca btl_tcp_if_include 192.168.0.0/16 -hostfile $nodes_file --map-by node -np ${num_procs} mdtest -C -d /mnt/client/mdtest-4y -i 1 -I ${files_per_dir} -z ${DEPTH} -b ${WIDTH} -L -T  -F -u -w 0
done
