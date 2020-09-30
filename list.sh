#! /bin/bash
function read_dir(){
    num=1
    for file in `ls -f $1` #注意此处这是两个反引号，表示运行系统命令
    do
       if [ -d $1"/"$file ] #注意此处之间一定要加上空格，否则会报错
       then
          read_dir $1"/"$file
       else
         echo $1"/"$file"#file num: $num" #在此处处理文件即可
      	 rm -fr $1"/"$file 
         #md5sum $1"/"$file
       fi
       ((num++))
    done
} 
read_dir $1
#读取第一个参数
