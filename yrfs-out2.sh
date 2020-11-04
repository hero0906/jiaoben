#!/bin/bash
#BEGIN for 2020.03.20 ; UPDATE for 2020.03.23
if [ -z $1 ]
then
	echo Please assign the result directory...
	exit 1
fi

#定义fio结果目录
dirTmp="$1"
dir=`cd $dirTmp && pwd`

#确定共有多少个粒度
ioSize=`ls $dir | awk -F '_' '{print $1}' | sort -n | uniq`

#定义-每个粒度下都有哪些job
Jobs () {

ls $dir | grep $1 | awk -F "_" '{print $4}' | sort -n | uniq

}

#定义抓取规则
IOPS () {

grep IOPS $1 | sed -r 's/.*IOPS=(.*),.*/\1/' 

}

BW () {

grep BW $1 | sed -r 's/.*BW=(.*)\ .*/\1/'

}

Lat () {

tmpLat1=`grep \ lat.*sec\): $1 | sed -r 's/.*avg=(.*),.*/\1/'`
tmpLat2=`grep \ lat.*sec\): $1 |sed -r 's/.*\((.*)\):.*/\1/'`
if [ -z $tmpLat2 ] ; then tmpLat2=Null ; fi
echo ${tmpLat1}\(${tmpLat2}\)

}

echo " " > YrFS-Fio-Test.log
#收集结果
for ioSize in $ioSize
do
	echo "+-------+----------+---------------+---------------+------+----------+---------------+---------------+------+" >> YrFS-Fio-Test.log
	echo "IO-Size Read-IOPS Read-BW Read-Lat R-Jobs Write-IOPS Write-BW Write-Lat W-Jobs" |
	awk '{printf "|%-7s|%-10s|%-15s|%-15s|%-6s|%-10s|%-15s|%-15s|%-6s|\n",$1,$2,$3,$4,$5,$6,$7,$8,$9}' >> YrFS-Fio-Test.log
	echo "+-------+----------+---------------+---------------+------+----------+---------------+---------------+------+" >> YrFS-Fio-Test.log
	for Jobs in `Jobs $ioSize`
	do
		r_iops=`IOPS ${dir}/${ioSize}_*read_jobs_${Jobs}`
		r_bw=`BW ${dir}/${ioSize}_*read_jobs_${Jobs}`
		r_lat=`Lat ${dir}/${ioSize}_*read_jobs_${Jobs}`
		w_iops=`IOPS ${dir}/${ioSize}_*write_jobs_${Jobs}`
		w_bw=`BW ${dir}/${ioSize}_*write_jobs_${Jobs}`
		w_lat=`Lat ${dir}/${ioSize}_*write_jobs_${Jobs}`
		if [ -z $r_iops ] ; then r_iops=Null ; fi
		if [ -z $r_bw ] ; then r_bw=Null ; fi
		if [ -z $r_lat ] ; then r_lat=Null ; fi
		if [ -z $w_iops ] ; then w_iops=Null ; fi
		if [ -z $w_bw ] ; then w_bw=Null ; fi
		if [ -z $w_lat ] ; then w_lat=Null ; fi
		echo ${ioSize} ${r_iops} ${r_bw} ${r_lat} ${Jobs} ${w_iops} ${w_bw} ${w_lat} ${Jobs} |
		awk '{printf "|%-7s|%-10s|%-15s|%-15s|%-6s|%-10s|%-15s|%-15s|%-6s|\n",$1,$2,$3,$4,$5,$6,$7,$8,$9}' >> YrFS-Fio-Test.log
	done
	echo "+-------+----------+---------------+---------------+------+----------+---------------+---------------+------+" >> YrFS-Fio-Test.log
	echo " " >> YrFS-Fio-Test.log
	echo " " >> YrFS-Fio-Test.log
done

#可视化显示结果
cat YrFS-Fio-Test.log 
