USER=root
PASSWORD=#@!1qaz@WSX3edc!@#

usage(){
    echo -e "\033[31m Usage:$0 <ip>\n \033[0m"
}

if [[ $# != 1 ]]
then
    usage
    exit
fi

NET=$1

if [[ ! -f ~/.ssh/id_rsa ]];then
    ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa &> /dev/null
fi

expect <<EOF
     spawn ssh-copy-id -i ${USER}@${NET}
     expect {
     "yes/no" { send "yes\n";exp_continue }
     "password" { send "${PASSWORD}\n" }
     }
EOF
#expect eof
