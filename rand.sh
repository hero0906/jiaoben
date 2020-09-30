#!/bin/bash
rand(){ 
    min=$1    
    max=$(($2-$min+1))    
    num=$(cat /dev/urandom | head -n 10 | cksum | awk -F ' ' '{print $1}')    
    echo $(($num%$max+$min))
} 
for i in `seq 4`;do
    rnd=$(rand 1 254)
    num=`expr $i - 1`
    ip[$num]=$rnd
done
ip=${ip[@]}
ip=`echo $ip | tr ' ' '.'`
echo $ip
#exit 0
