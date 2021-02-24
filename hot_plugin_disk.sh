osd_node=`yrcli --osd --type=oss|awk 'NR >1'|shuf -n 1`
host_ip=`cat $osd_node|awk '{print $2}'`
targeid=`cat $osd_node|awk '{print $1}'` 
dev=`lsblk |grep -B 1 |grep -B 1 '└─'|awk 'NR==1{print $1}'`
