	
for cache in native none;do
    sed -i "s/tuneFile.*/tuneFileCacheType             = ${cache}/" /etc/yrfs/yrfs-client.conf
    cat /etc/yrfs/yrfs-client.conf|grep tuneFileCacheType
    while true;do
        echo -e "stop client"
        systemctl stop yrfs-client
        status=`lsmod|grep yrfs`
        mnt=`findmnt /mnt/yrfs`
        if [[ -z $status ]] && [[ -z $mnt ]];then
            echo -e "start client"
            systemctl start yrfs-client
    	    mnt=`findmnt /mnt/yrfs`
            if [[ -n $mnt ]];then
                echo -e "cache type: $cache script run" 
  		python ./fiotest.py
    	    	break
            fi
        else
            continue
        fi
    done
done
#sed 's/tuneFile.*/tuneFileCacheType             = native/' /etc/yrfs/yrfs-client.conf
#sed 's/tuneFile.*/tuneFileCacheType             = none/' /etc/yrfs/yrfs-client.conf
