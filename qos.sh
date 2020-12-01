#!/usr/bin/env bash
add(){
    dir=$1
    echo -e "`date` $1"
    dirs=/mnt/yrfs$dir
    if [[ ! -d $dirs ]];then
        mkdir -p $dirs
    fi
    bps=200M
    iops=5000
    ops=5000

    # tbps=50M
    # tiops=500
    # mops=500
    if [[ $2 == "-t" ]];then
        echo -e "total set qos"
        yrcli --setqos --tbps=$bps --tiops=$iops --mops=$ops --path=$dir --unmounted
    else
        echo -e "single set qos"
        yrcli --setqos --rbps=$bps --wbps=$bps --wiops=$iops --riops=$iops --mops=$ops --path=$dir --unmounted
    fi
}


list(){
    echo -e `date`
    yrcli --getqos
}

update(){
    dir=$1
    echo -e "`date` $1"
    #limit=$(echo $RANDOM)
    limit=100
    yrcli --setprojectquota --unmounted --path=$dir --spacelimit=${limit}G --inodelimit=$limit --update
}

del(){
    dir="$1"
    echo -e "`date` $1"
    yrcli --rmqos --path=$dir --unmounted --force
}

usage(){
    echo -e "\033[31m Usage:$0 <add|del|list> path\n
    add <path> <-t>: add quota dir,-t add tolal qos set\n
    del <path>: del quota dir\n
    list: normal list quota dir \033[0m\n"
}



if [[ $# == 2 ]];then
    if [[ $1 == "add" ]];then
       add $2
    elif [[ $1 == "del" ]];then
       del $2
    elif [[ $1 == "update" ]];then
       update $2
    else
       usage 
       exit
    fi
elif [[ $1 == "add" && $3 == "-t" ]];then
    add $2 $3 
elif [[ $# == 1 && $1 == "list" ]];then
    list
else
    usage
    exit
fi
