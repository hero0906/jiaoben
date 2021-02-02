file=/etc/sysctl.conf
if [[ $1 == "start" ]];then
   # sed -i "s/^net.ipv6.conf.all.disable_ipv6.*/net.ipv6.conf.all.disable_ipv6 =0/g" $file
   # sed -i "s/net.ipv6.conf.default.disable_ipv6.*/net.ipv6.conf.default.disable_ipv6=0/g" $file
   # sysctl -p
    sysctl -w net.ipv6.conf.all.disable_ipv6=0
    sysctl -w net.ipv6.conf.default.disable_ipv6=0
elif [[ $1 == "stop" ]];then
    #sed -i "s/^net.ipv6.conf.all.disable_ipv6.*/net.ipv6.conf.all.disable_ipv6 =1/g" $file
    #sed -i "s/net.ipv6.conf.default.disable_ipv6.*/net.ipv6.conf.default.disable_ipv6=0/1" $file
    #sysctl -p
    sysctl -w net.ipv6.conf.all.disable_ipv6=1
    sysctl -w net.ipv6.conf.default.disable_ipv6=1
else
    echo -e "\033[35m\nUsage: $0 <start|stop>.\n
	    start: ipv6 service\n
            stop:  ipv6 service\n\033[0m"
fi

