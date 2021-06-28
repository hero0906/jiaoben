HOSTS=("192.168.12.161" "192.168.12.162" "192.168.12.163" "192.168.12.164")
mountip=`cat /etc/mtab |grep nfs|awk -F 'mountaddr=' 'NR>1{print $2}'|awk -F ',' '{print $1}'`
move(){
    for ip in ${HOSTS[@]};do
            stat=$(ssh $ip "ip addr|grep $mountip")
            echo -e "`date`|\t\033[34m ssh node: $ip \033[0m"
            if [[ -n $stat ]];then
                echo -e "`date`|\t\033[34m nfs mount ip in node: $ip\033[0m"
                nfs_current_ip=$ip
                break
            fi
    done

    while true;do
        ip=`shuf -e -n 1 ${HOSTS[@]}`
        echo -e "`date`|\t\033[34m random select migration ip: $ip.\033[0m"
        if [[ $ip != $nfs_current_ip ]];then 
            nfs_will_ip=$ip
            node_ctdb_id=$(ssh $nfs_will_ip "ctdb status|grep $nfs_will_ip|awk -F ':' '{print \$2}'|awk '{print \$1}'") 
            echo -e "`date`|\t\033[34m ctdb will move ip: $mountip to node: $nfs_will_ip, node id: $node_ctdb_id.\033[0m"
            break
        fi
    done
 
    move_cmd="ctdb moveip $mountip $node_ctdb_id"
    echo -e "`date`|\t\033[34m ssh $nfs_will_ip cmd: $move_cmd.\033[0m"
    ssh $nfs_will_ip $move_cmd
    if [[ $? -eq 0 ]];then
        echo -e "`date`|\t\033[34m $move_cmd success.\033[0m"
    else
        echo -e "`date`|\t\033[35m $move_cmd failed.\033[0m"
        exit
    fi
}
times=1
while true;do
    echo -e "test loops: $times>>>>>>>>>>>>>>>>>>>>>>>"
    move
    ((times++))
done
