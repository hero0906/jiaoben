for i in `seq 3 6`;do 
        ip=192.168.69.$i
	echo -e "[`date`]\t|\t$ip"
        date;ipmitool -H $ip -U ADMIN -P ADMIN chassis bootdev pxe
        date;ipmitool -H $ip -U ADMIN -P ADMIN power reset
done
#ipmitool -H 192.168.69.4 -U ADMIN -P ADMIN power on
