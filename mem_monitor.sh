#!/bin/bash

cluster_ip=`cat /etc/hosts|grep node|awk '{print $1}'`
USER=root
PASSWORD=#@!1qaz@WSX3edc!@#

Usage(){
    echo -e "\nUsage: $0 <OPTION>"
    echo " m    Monitor virtual memory of progress,when the monitor is started,and you want stop it,you must manually,you can press \"Ctrl+C\"."
    echo " c    Collect the orignal data for other node.But first you need to set up ssh keys-free links."
    echo " a    Analyse the orignal data if the PID of progress changed."
    echo " g    Put the data into images,but you have analyse the orignal data first."
    echo " r    Back up the test data,so you better running this command after running m;c;a;g command,to ensure that the backup data is up to date."
}

progress_mem(){

    mem_data=$6

    if [ -z ${mem_data} ];then

        return

    fi

    fileName=/mnt/monitor_data/orignal_data/$2-$3.dat

    if [ -e ${fileName} ];then

        echo -e "$5\t" "$4\t" "$7\t\t" "$1\t\t" "\t$6">>/mnt/monitor_data/orignal_data/$2-$3.dat

    else

        echo -e "\t""\ttime\t\t" "pid\t\t" "timer\t\t" "$2-$3">>/mnt/monitor_data/orignal_data/$2-$3.dat
        echo -e "$5\t" "$4\t" "$7\t\t" "$1\t\t" "\t$6">>/mnt/monitor_data/orignal_data/$2-$3.dat

    fi
}

ssh_key(){
    
    if [[ ! -f ~/.ssh/id_rsa ]];then
        ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa &> /dev/null
    fi
    for ip in $cluster_ip;do 
expect <<EOF
        spawn ssh-copy-id -i ${USER}@${ip}
        expect {
          "yes/no" { send "yes\n";exp_continue }
          "password" { send "${PASSWORD}\n" }
          } 
EOF
    done
}


# Set up directory to storage monitor data and image.
init_dir(){

    cd /mnt
    
    dir_name="monitor_data"
    data_path="orignal_data"
    analy_path="analy_data"
    png_path="image"
    record_path="record"
    password="Passw0rd"
    
    if [ -d ${dir_name} ];then
        echo "DIR monitor_data exist"
        cd $dir_name
    else
        mkdir $dir_name
        cd $dir_name
    fi
    
    if [ -d ${data_path} ];then
        echo "DIR orignal_data exist"
    else
        mkdir $data_path
    fi
    
    if [ -d ${analy_path} ];then
        echo "DIR analy_data exist"
    else
        mkdir $analy_path
    fi
    
    if [ -d ${png_path} ];then
        echo "DIR image exist"
    else
        mkdir $png_path
    fi
    
    if [ -d ${record_path} ];then
        echo "DIR record exist"
    else
        mkdir $record_path
    fi
}

monitor(){

     echo -e "monitor running>>>>>>>>>>>>>>>>>>"
     rm -rf /mnt/monitor_data/orignal_data/*.dat

     #获取本地ip 
     local_ip=`ifconfig eth0|grep -w inet|awk '{print $2}'`
     echo $local_ip

     echo "monitor..."

     timer=0
     line=1

     #开始监控
     pids=(mds0 mds1 yrfs-storage yrfs-mgmtd yrfs-admon etcd)
     echo -e ${pids[@]}

     while((1))
         do  
            {
             #获取系统当前时间
             time=`date +%Y/%m/%d-%H:%M:%S`
             n=0
 
             for pid in "${pids[@]}"
             do 

                 pid_num=`ps axu|grep -w $pid|grep -v grep|awk '{print $2}'`
                 pid_mem=`ps axu|grep -w $pid|grep -v grep|awk '{print $6}'`
                 progress_mem $timer $local_ip $pid $time $line $pid_mem $pid_num
                
             done   
             let line=$line+1
             sleep 10
             let timer=$timer+10 
             }
         done
}

collect(){

     node_ip=(`grep "node" /etc/hosts|awk '{print $1}'|grep -v $local_ip`)
     for i in ${node_ip[@]};do
         echo $i
         sshpass -p $PASSWORD scp @$i:/mnt/monitor_data/orignal_data/*.dat /mnt/monitor_data/orignal_data/

     done
}

analyse(){
     rm -rf /mnt/monitor_data/abnormal.txt

     path=/mnt/monitor_data/orignal_data/
     path_1=/mnt/monitor_data/analy_data/

     #分析报告文件的路径及名称
     analy_file=/mnt/monitor_data/abnormal.txt

     rm -rf ${path_1}*.dat

     fileName=(`ls $path`)

     for i in ${fileName[@]};do
         #数据文件中的pid是否有变化的标志位
         flag=0

         n=0

         #该标志首先指向数据的第一行，下一次指向pid发生变化的第一行，这样就可以获取到这之间pid没有发生变化的行数，将其重新写入一个新的文件，以便区分
         data_start_line=2

         #获取文件的总行数（即包含第一行表头）
         data_line=`sed -n '$=' ${path}$i`

         #设定一个标志位，用来判断下面循环查询pid是否到最后一行
         line_1=2

         echo $i

         pid_array=(`cat $path$i|grep -v pid|awk '{print $3}'`)

         for j in ${pid_array[@]};do


             #开始的时候只获取到数据的第一行(文件的第二行)的pid，所以不用比较pid有没有变化，所以判断条件是n>0
             if ((n > 0));then

             #如果发现前后两个pid不同，则说明pid发生变化，将信息写入报告日志，然后按照pid将数据分成不同的文件
                 if (($j != $last_pid));then

                     let m=$n+1
                     let l=$n+2

                     echo "警告：$i数据文件中第$n行的pid和第$m行的pid发生变化！">>$analy_file
                     echo   >>$analy_file

                     sed -n "1p" "$path$i">>$analy_file
                     sed -n "${m}p" "$path$i">>$analy_file
                     sed -n "${l}p" "$path$i">>$analy_file
                     echo   >>$analy_file
                     echo   >>$analy_file

                     sed -n "1p" "$path$i">>${path_1}$last_pid-$i
                     sed -n "$data_start_line,${m}p" "$path$i">>${path_1}$last_pid-$i

                     flag=1

                     data_start_line=$l

                 fi

             fi

             if ((line_1 == data_line));then

                 sed -n "1p" "$path$i">>${path_1}$j-$i
                 sed -n "$data_start_line,${data_line}p" "$path$i">>${path_1}$j-$i

             fi

             last_pid=$j
             let n=$n+1
             let line_1=$line_1+1

         done

         if ((flag == 0));then

             cp $path$i ${path_1}$j-$i
         fi

     done
}

gplot(){

     rm -rf /mnt/monitor_data/image/*.png

     path=/mnt/monitor_data/analy_data/

     ls $path>>/mnt/monitor_data/file_name.txt

     sed -i "s/.dat//g" `grep .dat -rl /mnt/monitor_data/file_name.txt`

     progressName=$(cat /mnt/monitor_data/file_name.txt)

     rm -rf /mnt/monitor_data/file_name.txt

     ylabelName="memory"

     for i in ${progressName[@]};do

         time_start=`sed -n "2p" "$path${i}.dat"|awk '{print $2}'`

         line=`sed -n '$=' "$path${i}.dat"`

         time_stop=`sed -n "${line}p" "$path${i}.dat"|awk '{print $2}'`

         xlabelName="timer(${time_start}----${time_stop})"

         echo "
             set xlabel \"$xlabelName\"
             set ylabel \"$ylabelName\"
             set title \"$i\"
             set term png lw 1
             set output \"/mnt/monitor_data/image/$i.png\"
             plot \"${path}$i.dat\" using 4:5 w lp pt 7 title \"$i\"
             set output
              "|gnuplot

     done        
}

record(){

     cd /mnt/monitor_data
     time0=`date +%Y-%m-%d-%H":"%M":"%S`
     echo "$time0"
     mkdir ./record/$time0

     cp -r ./analy_data ./record/$time0
     cp -r ./image ./record/$time0
     cp -r ./orignal_data ./record/$time0

     filename="abnormal.txt"
     if [ -e ${filename} ];then
         cp -r ./abnormal.txt ./record/$time0
     fi          
}

if [[ $# == 1 ]];then
    if [[ $1 == "m" ]];then
       init_dir
       monitor
    elif [[ $1 == "a" ]];then
       analyse
    elif [[ $1 == "g" ]];then
       gplot
    elif [[ $1 == "r" ]];then
       record
    else
       Usage 
    fi
else
    Usage
fi
