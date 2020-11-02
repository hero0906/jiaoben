#coding = utf-8
import os
import subprocess


filename = "/mnt/yrfs/testfile"
sync = "sync;echo 3 > /proc/sys/vm/drop_caches"

def shell(cmd):
    stderr = ""
    re = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    if stderr:
        print re.stdout.read().strip(), re.stderr.read().strip()
    else:
        return re.stdout.read().strip()

def log_dir():
    kernel = os.system("uname -a|awk '{print $3}'")


def fio_run(bs, rw, numjobs):
    fio_cmd = "fio --ioengine=psync --name=test --filename={0} --ramp_time=5 --size=50G --runtime=600 --group_reporting\
 --bs={1} --rw={2} --numjobs={3} --iodepth=64 --output={1}{2}{3}".format(filename, bs, rw, numjobs)
    return fio_cmd

def dd_run(bs, rw):
    if rw == "read":
        if bs in "4K, 4k":
            count = 50000
        elif bs in "1M, 1m":
            count = 10000
        dd_cmd = "dd if={0} of=/dev/null bs={1} count={2}".format(filename, bs, count)
    if rw == "write":
        if bs in "4K, 4k":
            count = 50000
        elif bs in "1M, 1m":
            count = 10000
        dd_cmd = "dd if=/dev/zero of={0} bs={1} count={2}".format(filename, bs, count)
    return dd_cmd


os.system("sync;echo 3 > /proc/sys/vm/drop_caches")
print "fio test bs:4k,rw:randread,numjobs:32"
os.system(fio_run("4K","randread",32))

for bs in ("4k","1M"):
    for rw in ("write","read","randread"):
        os.system("sync;echo 3 > /proc/sys/vm/drop_caches")
	print "fio test bs:%s rw:%s, numjobs:1"%(bs,rw)
        os.system(fio_run(bs,rw,1))

for bs in ("4k","1M"):
    os.system("sync;echo 3 > /proc/sys/vm/drop_caches")
    print "dd test bs:%s,rw:read" %(bs)
    os.system(dd_run(bs,"read"))
