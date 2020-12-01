dirs=""
for((n=1;n<16;n++));do
    dir=/mnt/yrfs/qos/test_qos00$n:
    dirs=$dirs$dir
done
seed=$(echo $RANDOM)
rw="write"
rand_distribution=random:1/zipf:4/pareto:2/normal:1/zoned:1/zoned_abs:1
rand_gener=(tausworthe lfsr tausworthe64 tausworthe)
sync=1
ioengine=(sync psync vsync pvsync pvsync2 io_uring rdma posixaio)
verify=(md5 crc64 crc32c crc32 crc16 crc7 sha256 )
numjobs=1
#dirs="/tmp"
output="logs/fio_"`date +%H:%M_%m-%d`".log"

fio_run="fio \
--group_reporting \
--ioengine=psync \
--directory=$dirs \
--name=test \
--bs=4K \
--numjobs=$numjobs \
--size=50M \
--nrfiles=160
--rw=$rw \
--verify=crc64 \
--loops=1 \
--allrandrepeat=1 \
--continue_on_error=verify \
--random_distribution=$rand_distribution \
--random_generator=${rand_gener[2]} \
"

fio_verify="fio \
--directory=$dirs \
--name=test \
--numjobs=$numjobs \
--verify_only \
--continue_on_error=verify \
"
#--eta-newline=1 \
#--eta-interval=1 \
#--percentage_random=50 \
#--fallocate=posix \
#--verify_state_save=1 \
#--do_verify=1 \
#other="--norandommap"
#--rwmixwrite=20 \
#--debug=io \

if [[ $# != 1 ]]
then
    echo -e "Parameter cannot bu null\n
    Usage:$0 <verify|run> \n
    run:run fio test.\n
    verify:verify fio data.\n"
    exit
fi

if [[ $1 == "run" ]]
then
    echo -e "`date`# fio test running."
    $fio_run

elif [[ $1 == "verify" ]]
then
    echo -e "`date`# fio verify running."
    $fio_verify
fi
