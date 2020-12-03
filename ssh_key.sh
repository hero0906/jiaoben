usage(){
    echo -e "\033[31m Usage:$0 <ip>\n\033[0m"
}

if [[ $# != 1 ]]
then
    usage
    exit
fi

NET=$1
USER=root
PASSWORD=Passw0rd

ssh_no_key(){
if [[ ! -f ~/.ssh/id_rsa ]];then
    ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa &> /dev/null
fi

#for i in {1..254} ; do
#{

    expect <<EOF
    spawn ssh-copy-id -i ${USER}@${NET}
    expect {
        "yes/no" { send "yes\r";exp_continue }
        "password:" { send "${PASSWORD}\r" }
    }
    expect eof
EOF
}

#}&
#done
#wait
