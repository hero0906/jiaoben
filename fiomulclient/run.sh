filename="/caoyi/yrfs/file_test003"

check(){
    layer=$1
    num=1
    while true;do
        stat=`yrcli --getentry $filename -u|grep Layer|awk -F ':' '{print $2}'`
        if [[ $stat == $layer ]];then
            echo -e "`date`|file current layer $layer!!!"
            break
        fi
        echo -e "`date`|check $filename layer in $stat,times: $num."
        sleep 10
        ((num++))
    done
}

run(){

    fio --client=nodelist config --verify=crc64 
    if [[ $? -ne 0 ]];then
        echo -e "fio run error."
        exit
    fi

    #check "Local"

    echo -e "`date`|begin sleep 100"
    sleep 200
    echo -e "`date`|over sleep 100"

    yrcli --tiering --op=flush --id=14
    if [[ $? -ne 0 ]];then
        echo -e "`date`|s3 flush command error."
        exit
    fi
    #check "S3"

}

while true;do
   run
done
