lun="7:0"
bps_r="/sys/fs/cgroup/blkio/blkio.throttle.read_bps_device"
bps_w="/sys/fs/cgroup/blkio/blkio.throttle.write_bps_device"
iops_r="/sys/fs/cgroup/blkio/blkio.throttle.read_iops_device"
iops_w="/sys/fs/cgroup/blkio/blkio.throttle.write_iops_device"
slow="8192"
fast="1024000000000"

if [ $# -ne 1 ];then
    echo -e "Usage:$0 0|1\n 0 is set fast\n 1 is set slow"
    exit 
fi

if [ $1 -eq 0 ];then
    echo "set disk fast"
    echo "$lun $fast" > bps_r
    echo "$lun $fast" > bps_w
    #echo "$lun $fast" > iops_r
    #echo "$lun $fast" > iops_w
else
    echo "set disk slow"
    echo "$lun $slow" >bps_r
    echo "$lun $slow" >bps_w
fi
