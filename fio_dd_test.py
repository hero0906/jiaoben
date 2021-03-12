#coding = utf-8
import os
import subprocess
from time import ctime
import re

filename = "/mnt/yrfs/testfile"
mountdir = "/mnt/yrfs"
sync = "sync;echo 3 > /proc/sys/vm/drop_caches"
clientip = ["192.168.48.18"]
logpath = "/home/caoyi/log"

def shell(cmd):
    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    #if stderr:
    #    print re.stdout.read().strip(), re.stderr.read().strip()
    out = p.stdout.read()
    err = p.stderr.read()
    #else:
    if out:
        return out.strip()
    elif err:
        return err.strip()
    else:
        return None

def fio_run():
    numjobs = 1

    for bs in ("4k","1M"):
        if bs == "4k":
            rws = ("randwrite","randread")
        else:
            rws = ("write","read")
        for rw in rws:
            fio_cmd = "fio --ioengine=libaio --name=test --filename={0} --ramp_time=10 --size=50M --runtime=10 --group_reporting\
                    --bs={1} --rw={2} --numjobs={3} --iodepth=64".format(filename, bs, rw, numjobs)
            print(ctime() + "|\tdrop cache")
            shell("sync;echo 3 > /proc/sys/vm/drop_caches")
            print(ctime() + "|\tfio test bs:%s rw:%s, numjobs:1" % (bs,rw))
            res = shell(fio_cmd)
            try:
                iops = re.findall(r": (IOPS.*?/s) ",res)
                print(ctime() + "|\tRESULT:\t" + "".join(iops))
            except Exception,e:
                print(ctime() + "|\tget result failed.")
                print(res)

def dd_run():

    for bs in ("4K","1M"):
            if bs == "4K":
                count = 200
            else:
                count = 50

            shell("sync;echo 3 > /proc/sys/vm/drop_caches")
            dd_write = "dd if=/dev/zero of={0} bs={1} count={2}".format(filename, bs, count)
            print(ctime() + "|\tdd test bs: %s, rw: write cmd: %s" % (bs, dd_write))
            res_w = shell(dd_write)
            bw = re.findall(r"s, (.*?/s)",res_w)
            print(ctime() + "|\tRESULT:\t" + "".join(bw))

            shell("sync;echo 3 > /proc/sys/vm/drop_caches")
            dd_read = "dd if={0} of=/dev/null bs={1} count={2}".format(filename, bs, count)
            print(ctime() + "|\tdd test bs: %s, rw: read cmd: %s" % (bs, dd_read))
            res_r = shell(dd_read)
            bw = re.findall(r"s, (.*?/s)",res_r)
            print(ctime() + "|\tRESULT:\t" + "".join(bw))

def vdbench_run():
    rootdir = "/home/vdbench"
    files = "1"
    size = "50m"
    bss = ("4K","1M")
    threads = 1
    elapsed = 20
    operations=("write","read")
    testdir = mountdir + "/vdbench/"

    if not os.path.exists(testdir):
        os.makedirs(testdir)

    for bs in bss:
        if bs == "4K":
            fileio = "random"
        else:
            fileio = "sequential"

        for operation in operations:
            config = []
            config.append("messagescan=no")
            config.append("hd=default,vdbench=%s,user=root,shell=ssh" % rootdir)
            for hd in range(len(clientip)):
                config.append("hd=hd%s,system=%s" % (hd,clientip[hd]))
            config.append("fsd=fsd1,anchor=%s,depth=1,width=1,files=%s,size=%s,shared=yes" % (testdir,files,size))
            config.append("fwd=default,operation=%s,xfersize=%s,fileio=%s,fileselect=random,threads=%s" % (operation,bs,fileio,threads))
            for hd in range(len(clientip)):
                config.append("fwd=fwd{hd},fsd=fsd1,host=hd{hd}".format(hd=hd))
            config.append("rd=rd1,fwd=fwd*,fwdrate=max,format=restart,elapsed=%s,interval=1" % elapsed)

            with open("vdbench_config","w+") as f:
                for line in config:
                    f.write(line)
                    f.write("\n")

            logdir = logpath + "/" + bs + operation + fileio
            if not os.path.exists(logdir):
                os.makedirs(logdir)

            print(ctime() + "|\tvdbench test %s %s %s" % (bs,fileio,operation))
            res = shell("%s/vdbench -f vdbench_config -o %s" % (rootdir,logdir)) 

            try:
                #avg_res = res.split("\n")[-8]
                #avg = avg_res.split()[13]
                avg_res = re.findall("(avg.*)",res)
                bw_res = avg_res[-1].split()[12]
                print(ctime() + "|\tRESULT:\t%s MB/s" % bw_res)
            except Exception,e:
                print(ctime() + "|\tget result failed.")
                print(res)

def mdtest_run():

    with open("nodelist","w+") as f:
        for ip in clientip:
            f.write(ip)
            f.write("\n")

    DEPTH=1
    WIDTH=10
    num_files=100
    testdir = mountdir + "/cy-mdtest"
    num_procs = shell("cat /proc/cpuinfo | grep \"cpu cores\" | uniq|awk '{print $4}'")
    files_per_dir = int(num_files / int(num_procs) / WIDTH) 

    if os.path.exists(testdir):
        shell("rm -fr %s" % testdir)
    shell("mkdir -p " + testdir)

    cmd = "mpirun --allow-run-as-root --mca -hostfile nodelist --map-by node -np " + num_procs + \
          " mdtest -C -d " + testdir + " -i 1 -I " + str(files_per_dir) + " -z " + str(DEPTH) + " -b " + str(WIDTH) + \
          " -L -T  -F -u -w 0"
    print(ctime() + "|\t mdtest test files: %s numprocs: %s" % (num_files,num_procs))
    res = shell(cmd)
    try:
        create_res = re.findall("(File creation.*)",res)
        stat_res = re.findall("(File stat.*)",res)
        print("".join(create_res))
        print("".join(stat_res))
    except Exception,e:
        print(ctime() + "|\tget result failed.")
        print(res)



#os.system("sync;echo 3 > /proc/sys/vm/drop_caches")
#print "fio test bs:4k,rw:randread,numjobs:32"
#os.system(fio_run("4K","randread",32))
#dd_run()
#fio_run()
vdbench_run()
#mdtest_run()
