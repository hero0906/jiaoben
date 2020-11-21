server=`cat /etc/hosts|grep node|awk '{print $1}' | tr '\n' ',' `
server="192.168.45.[11-14]"
client="192.168.48.[17-18]"
if [[ $# == 1 ]];then
    if [[ $1 == "s" ]];then
	ip=$server
        echo -e "`date` $ip"
        pdsh -w $ip
    elif [[ $1 == "a" ]];then
        ip=$server,$client
        echo -e "`date` $ip"
        pdsh -w $ip
    elif [[ $1 == m ]];then
        ip="192.168.45.[11-13]"
        echo -e "`date` $ip"
        pdsh -w $ip
    elif [[ $1 == c ]];then
	ip=$client
        echo -e "`date` $ip"
        pdsh -w $ip
    else
        echo -e "\033[31m Usage: $0 <s|a|m>\n
        s: connect server ip\n
        a: connect all ip server and client\n 
        c: connect client ip\n
        m: connect mgmt node\n \033[0m\n"
    fi
else
   echo -e "\033[31m Usage: $0 <s|a|m|c>\n
   s: connect server ip\n
   a: connect all ip server and client\n
   c: connect client ip\n
   m: connect mgmt node \033[0m\n"
fi
