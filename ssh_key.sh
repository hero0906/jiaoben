usage(){
    echo -e "\033[31m Usage:$0 <ip>\n"
}

if [[ $# != 1 ]]
then
    usage
    exit
fi

NET=$1
USER=root
PASSWORD=Passw0rd

if [[ ! -f ~/.ssh/id_rsa ]];then
    ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa &> /dev/null
fi

#for i in {1..254} ; do
#{
expect <<EOF
spawn ssh-copy-id -i ${USER}@${NET}
expect {
  "yes/no" { send "yes\n";exp_continue }
  "password" { send "${PASSWORD}\n" }
}
expect eof
EOF
#}&
#done
#wait
