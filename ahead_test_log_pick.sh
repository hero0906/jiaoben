if [[ $# == 1 ]];then
    cd $1
    for i in `ls dd*`;do echo -n "$i:  ";cat $i|grep copied|tail -n 1|awk -F ',' "{print $3}";echo -e "\n";done
    for i in `ls fio_*`;do echo -n "$i: ";cat $i|grep BW=|awk '{print $3}';echo -e "\n";done
    cd ..
else
    echo -e "\033[31m Usage $0 <path> \033[0m\n"
fi
