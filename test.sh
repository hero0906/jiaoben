bs="4K"
if [[ bs -eq "4K" ]];then
    fileio="random"
elif [[ bs == "1M" ]];then
    fileio="sequential"
else
    echo -e "bs not 4k or 1m test quit!"
    exit
fi

