#!/usr/bin/bash

pre_dir="/mnt/yrfs"

add(){
    num=$1
   
    systemctl stop yrfs-client &&df -h

    for i in `seq $num`;do

        dirs=""
        dir_depth=10
        for dep in `seq $dir_depth`;do

            dir=`uuidgen |awk -F '-' '{print $2}'`
            #dir=`uuidgen`
            dirs=$dirs"/"$dir
            echo -e $dirs

            path=$pre_dir$dirs
            echo -e $path
            ssh 192.168.12.254 mkdir -p $path

            if [[ $dep == 1 ]];then
                #yrcli --acl --op=add --path=$dirs --ip=17.18.10.[50-60] --mode=ro
                yrcli --acl --op=add --path=$dirs --ip=17.18.10.[10-59,61-255] --mode=rw
		#echo "/mnt$dirs /etc/yrfs/yrfs-client.conf $dirs" |tee -a /etc/yrfs/yrfs-mounts.conf
            fi
 
            if [[ $dep == 3 ]];then
                yrcli --acl --op=add --path=$dirs --ip=17.18.10.60 --mode=ro
		echo "/mnt$dirs /etc/yrfs/yrfs-client.conf $dirs" |tee -a /etc/yrfs/yrfs-mounts.conf
            fi

            if [[ $dep == 4 ]];then
                yrcli --acl --op=add --path=$dirs --ip=17.18.10.60 --mode=rw
		echo "/mnt$dirs /etc/yrfs/yrfs-client.conf $dirs" |tee -a /etc/yrfs/yrfs-mounts.conf
            fi

            if [[ $((dep % 9)) == 0 ]];then
                yrcli --acl --op=add --path=$dirs --ip=17.18.10.60 --mode=ro
		echo "/mnt$dirs /etc/yrfs/yrfs-client.conf $dirs" |tee -a /etc/yrfs/yrfs-mounts.conf
            fi

        done
    done
    echo -e "configure over restart service"
    systemctl start yrfs-client&&df -h 
}

te(){

    echo -e "\033[31m test acl Permission>>>>>>>>>>>>>>>>>>>>>>>>> \033[0m"
    for mou in `df -h|grep mnt|awk '{print $6}'`;do
        echo -e "[`date`] touch file in $mou/test_file" 
        echo `uuidgen` |tee -a $mou"/test_file"
    done
}

del(){

    echo -e "\033[31m delete acl Permission>>>>>>>>>>>>>>>>>>>>>>>>> \033[0m"
    systemctl stop yrfs-client&&df -h
    > /etc/yrfs/yrfs-mounts.conf
    #sed -i '2,$d' /etc/yrfs/yrfs-mounts.conf
    for dir in `yrcli --acl --op=list|grep :|grep -vw /:|awk -F ':' {'print $1'}`;do
        echo -e "[`date`] delete acl path : $dir"
        yrcli --acl --op=del --path=$dir
        ssh 192.168.12.254 rm -fr /mnt/yrfs$dir
    done
    for mou in `df -h|grep mnt|awk '{print $6}'`;do
	umount -l $mou
	rm -fr $mou
    done
    modprobe -r yrfs
    systemctl start yrfs-client&&df -h

}

re(){
    systemctl stop yrfs-client&&df -h
    for mou in `df -h|grep mnt|awk '{print $6}'`;do
        umount -l $mou   
    done
    modprobe -r yrfs
    df -h
    systemctl start yrfs-client&&df -h
}

list(){
    echo -e "[`date`] \033[31m list cluster acl>>>>>>>>>>>>>>>>>>>>>> \033[0m"
    yrcli --acl --op=list
}

if [[ $# == 1 ]];then
    if [[ $1 == "add" ]];then
        add 1
    elif [[ $1 == "list" ]];then
        list
    elif [[ $1 == "del" ]];then
        del 
    elif [[ $1 == "te" ]];then
	te
    elif [[ $1 == "re" ]];then
	re
    else 
        echo -e "Usage: $0 <add|list|del|te>\n"
    fi
else
    echo -e "parameter not enough\n
    Usage: $0 <add|list|del|test|te|re>\n
    add: add acl and mount dir\n
    list: list all acl\n
    del: delete acl\n
    re: remount acl munt
    "
    exit
fi
