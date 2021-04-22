for i in `seq 6 9`;do 
        ip=10.16.2.$i
	echo -e "[`date`]\t|\t$ip"
        echo -e "\t";date;ipmitool -H $ip -U ADMIN -P ADMIN chassis bootdev pxe
        echo -e "\t";date;ipmitool -H $ip -U ADMIN -P ADMIN power reset
done
#ipmitool -H 192.168.69.4 -U ADMIN -P ADMIN power on
