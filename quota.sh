
add(){
    dir=$1
    echo -e "`date` $1"
    dirs=/mnt/yrfs$dir
    if [[ ! -d $dirs ]];then
        mkdir -p $dirs
    fi
    limit=$(echo $RANDOM)
    #limit=`expr $(echo $RANDOM) \* 1000`
    inode=`expr $limit \* 100` 
    #limit=100
    yrcli --setprojectquota --unmounted --path=$dir --spacelimit=${limit}G --inodelimit=$inode
}

list(){
    echo -e `date`
    yrcli --getprojectquota
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
   yrcli --rmprojectquota --path=$dir --unmounted
}

usage(){
   echo -e "\033[31m Usage:$0 <add|del|update> path
   add <path>: add quota dir
   del <path>: del quota dir
   update <path>: update quota dir
   list: normal list quota dir \033[0m"
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
elif [[ $# == 1 && $1 == "list" ]];then
   list
else
   usage
   exit
fi
