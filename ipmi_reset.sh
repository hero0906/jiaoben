for i in `seq 3 6`;do 
        ip=192.168.69.$i
        ipmitool -H $ip -U ADMIN -P ADMIN chassis bootdev pxe
        ipmitool -H $ip -U ADMIN -P ADMIN power reset
done
#ipmitool -H 192.168.69.4 -U ADMIN -P ADMIN power on

