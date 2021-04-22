#coding = utf-8
import os
import subprocess


filename = "/mnt/yrfs/testfile"
sync = "sync;echo 3 > /proc/sys/vm/drop_caches"
clientip = "192.168.48.18"
logpath = "/home/caoyi/log"

def shell(cmd):
    stderr = ""
    re = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    err = p.stderr.read()
    out = p.stdout.read()

    if err:
        return err.strip()
    else:
        return out.strip()

def log_dir():
    kernel = os.system("uname -a|awk '{print $3}'")


def fio_run(bs, rw, numjobs):
    fio_cmd = "fio --ioengine=libaio --name=test --filename={0} --ramp_time=10 --size=50G --runtime=600 --group_reporting\
 --bs={1} --rw={2} --numjobs={3} --iodepth=64 --output={logpath}/fio_{1}{2}{3}".format(filename, bs, rw, numjobs, logpath=logpath)
    return fio_cmd

def dd_run(bs, rw):
    if rw == "read":
        if bs in "4K, 4k":
            count = 100000
        elif bs in "1M, 1m":
            count = 50000
        dd_cmd = "dd if={0} of=/dev/null bs={1} count={2}|tee -a {logpath}/dd_{1}_read".format(filename, bs, count, logpath=logpath)
    if rw == "write":
        if bs in "4K, 4k":
            count = 100000
        elif bs in "1M, 1m":
            count = 50000
        dd_cmd = "dd if=/dev/zero of={0} bs={1} count={2}|tee -a {logpath}/dd_{1}_write".format(filename, bs, count, logpath=logpath)
    return dd_cmd

def vdbench_run(bs,rw):
    config="vd_config"
    with open(config,"w+") as f:
        f.write("messagescan=no")
        f.write("hd=default,vdbench=/home/vdbench,user=root,shell=ssh")
 	f.write("hd=hd1,system=%s" % clientip)

#os.system("sync;echo 3 > /proc/sys/vm/drop_caches")
#print "fio test bs:4k,rw:randread,numjobs:32"
#os.system(fio_run("4K","randread",32))

numjobs = 1
for bs in ("4k",):
    if bs == "4k":
	rws = ("randread",)
    else:
	rws = ("write","read")
    for rw in rws:
        os.system("sync;echo 3 > /proc/sys/vm/drop_caches")
	print "fio test bs:%s rw:%s, numjobs:1"%(bs,rw)
        os.system(fio_run(bs,rw,numjobs))

#for bs in ("4k","1M"):
#    for rw in ("write","read"):
#        os.system("sync;echo 3 > /proc/sys/vm/drop_caches")
#        print "dd test bs:%s,rw:%s" %(bs, rw)
#        os.system(dd_run(bs,rw))
