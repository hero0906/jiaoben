HOSTS=(`yrcli --node --type=mgmt|awk '{print $1}'`)
echo ${HOSTS[@]}

ENDPOINTS=${HOSTS[0]}:2379,${HOSTS[1]}:2379,${HOSTS[2]}:2379

map(){
   watch -n 2 "\
   yrcli --osd --type=mds
   yrcli --osd --type=oss
   #yrcli --group --type=oss
   yrcli --node --type=mgmt
   etcdctl --endpoints=$ENDPOINTS endpoint health"
}

cover(){
   watch -c -n 2 "
   #yrcli --recoverstat --type=oss --groupid=7; yrcli --recoverstat --type=oss --groupid=9
   yrcli --recoverstat --type=mds --groupid=1; yrcli --recoverstat --type=mds --groupid=2"
}

usage(){
    echo -e "\033[31m Usage:$0 <c|m>\n
    m: oss,mds,etcd,mgmt map status.\n
    c: mds recover status.\n \033[0m"
}
if [[ $# != 1 ]]
then
    usage
    exit
fi

if [[ $1 == "m" ]]
then
    map

elif [[ $1 == "c" ]]
then
    cover
else
    usage
fi
