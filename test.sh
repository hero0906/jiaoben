rm -fr /mnt/yrfs/quota_autotest/
mkdir -p /mnt/yrfs/quota_autotest/  
yrcli --setprojectquota --unmounted --path=quota_autotest --spacelimit=1M --inodelimit=8
sleep 10
dd if=/dev/zero of=/mnt/yrfs/quota_autotest/quota_autotest bs=1200K count=1 oflag=dsync
sleep 10
dd if=/dev/zero of=/mnt/yrfs/quota_autotest/quota_autotest1M bs=1200K count=1 oflag=dsync
