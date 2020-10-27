#coding = utf-8

import os
import subprocess
import commands
import time
import paramiko
import time
import logging


filename = "/mnt/yrfs/testfile"
sync = "sync&&echo 3 > /proc/sys/vm/drop_caches;sleep 1"
md5 = "md5sum " + filename 
#md5 = "md5sum /root/test" 
node_ip = "192.168.48.14"
kernel_cmd = "uname -a|awk '{print $3}'"

def logger(loglevel, log):
    log_level = {
            'critical': logging.critical,
            'error': logging.error,
            'warning': logging.warning,
            'info': logging.info,
            'debug': logging.debug
            }
    logging.basicConfig(level=logging.DEBUG,
            format='%(asctime)s %(filename)s[line:%(lineno)d] %(levelname)s %(message)s',
            filename='log/run_log',
            )
    console = logging.StreamHandler()
    console.setLevel(logging.INFO)
    formatter = logging.Formatter('%(levelname)-8s %(asctime)-4s %(message)s')
    console.setFormatter(formatter)
    logging.getLogger('').addHandler(console)
    log_level[loglevel](log)
    logging.getLogger('').removeHandler(console)

def ssh(cmd):
    #p = subprocess.call(cmd, stdout=None, stderr=None, shell=True)
    #p.wait()
    logger("info",cmd + "   running")
    os.system(cmd)


def install(ahead=False):
    stop = "systemctl stop yrfs-client"    
    remove = "rpm -qa|grep yrfs|xargs -I {} yum -y remove {}"
    noahead_rpm = "rpm -ivh /home/cy/yrfs_no_readahead/yrfs-*.rpm"
    ahead_rpm = "rpm -ivh /home/cy/yrfs_readahead/yrfs-*.rpm"
    yrfs_config = 'sed -i "s/^client_cache_type.*/client_cache_type                 = cache/" /etc/yrfs/yrfs-client.conf;\
		   sed -i "s/^mgmtd_hosts.*/mgmtd_hosts                       = 19.48.12.2,19.48.12.3,19.48.12.4/" /etc/yrfs/yrfs-client.conf'
    start = "systemctl start yrfs-client"
    rpm_now = "rpm -qa|grep yrfs;systemctl status yrfs-client"
    if ahead:
	rpm = ahead_rpm 
    else:
	rpm = noahead_rpm
    for pak in (stop, remove, rpm, yrfs_config, start, rpm_now):
        time.sleep(1)
        logger("info","%s is running" % pak)
	res = commands.getoutput(pak)
	logger("info",res)

def ssh2(ip, cmd):
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(ip,22,"root","Passw0rd",timeout=5)
        con_info = ip + " 22 root PasswOrd "
        stdin,stdout,stedrr = ssh.exec_command(cmd)
        out = stdout.readlines()
	out_str = " ".join(out)
	logger("info", con_info + out_str)
	return out_str
    except Exception,e:
        print e

def fio_run(bs, rw, numjobs):
    fio_cmd = "fio -engine=psync -name=test -filename={0} -ramp_time=5 -size=50G -runtime=600 -group_reporting\
 -bs={1} -rw={2} -numjobs={3} -time_based -iodepth=1 -output=fio_{1}{2}{3}.log".format(filename, bs, rw, numjobs)
    return fio_cmd

def dd_run(bs, rw):
    if rw == "read":
        if bs in "4K, 4k":
            count = 20000
        elif bs in "1M, 1m":
            count = 10000
        dd_cmd = "dd if={0} of=/dev/null bs={1} count={2} status=progress 2>>dd_{3}{1}.log".format(filename, bs, count, rw)
    if rw == "write":
        if bs in "4K, 4k":
            count = 10000000
        elif bs in "1M, 1m":
            count = 50000
        dd_cmd = "dd if=/dev/zero of={0} bs={1} count={2} status=progress 2>>dd_{3}{1}.log".format(filename, bs, count, rw)
    return dd_cmd

def md5_test():
   logger("info","client_md5 running")
   client_md5 = commands.getoutput(md5) 
   logger("info",client_md5)
   time.sleep(2)
   logger("info","node_md5 running")
   node_md5 = ssh2(node_ip, md5)
   with open("md5.log", "a") as f:
	f.write("client_md5sum:" + client_md5 + "\n")
	f.write("node_md5sum:" + node_md5)


def all_test():
   ssh(sync)
   ssh(fio_run("4K","randread","1"))
   ssh(sync)
   ssh(fio_run("4K","randread","32"))
   ssh(sync)
   ssh(fio_run("1M","randread","1"))

   ssh(sync)
   ssh(fio_run("4K","read","1")) 
   ssh(sync)
   ssh(dd_run("4K","read"))

   ssh(sync)
   ssh(fio_run("1M","read","1")) 
   ssh(sync)
   ssh(dd_run("1M","read"))
#
   ssh(sync)
   ssh(fio_run("4K","write","1"))
   md5_test() 
   ssh(sync)
   ssh(fio_run("1M","write","1"))
   md5_test()
   
def change_kernel():
    kernel_file = "/home/cy/kernel"
    ker = commands.getoutput("head -n 1 %s" %kernel_file)
    if ker:
           ssh("sed -i '1d' %s")%kernel_file
           ch_menu = "sed -i \"s/^saved_entry.*/saved_entry=%s/\" /boot/grub2/grubenv" %ker
	   ssh(ch_menu)
           ssh("reboot")
    else:
           logger("info","no used kernel,test over!!!!")
           exit()


if __name__ == "__main__":
        

#    kernel = (
#	  "CentOS Linux (4.12.14.20200406) 7 (Core)",
#	  "CentOS Linux (3.10.0-229.7.2.el7.x86_64) 7 (Core)",
#	  #"CentOS Linux (3.10.0-693.el7.x86_64) 7 (Core)",
#	  #"CentOS Linux (3.10.0-957.el7.x86_64) 7 (Core)",
#	  "CentOS Linux (4.19.13-default) 7 (Core)",
#	  "CentOS Linux (4.4.229-default) 7 (Core)")
    

    kernel = commands.getoutput("uname -a|awk '{print $3}'") 
    logger("info","%s test is running"%kernel)
    #noahead_dir = "/home/cy/log/noahead%s"%str(kernel)
    #ahead_dir = "/home/cy/log/ahead%s"%str(kernel)
    #ssh("mkdir -p %s %s"%(noahead_dir,ahead_dir))

    #make_logdir()
    #install(ahead=True)
    #all_test() 
    #ssh("mv /home/cy/*.log %s"%ahead_dir)
   #
    #install(ahead=False)
    all_test() 
    #ssh("mv /home/cy/*.log %s"%noahead_dir)

    #change_kernel()

#   ssh(sync)
#   ssh(fio_run("4K","randread","1"))
#   ssh(sync)
#   ssh(fio_run("4K","randread","32"))
#   ssh(sync)
#   ssh(fio_run("1M","randread","1"))
#
#   ssh(sync)
#   ssh(fio_run("4K","read","1")) 
#   ssh(sync)
#   ssh(dd_run("4K","read"))
#
#   ssh(sync)
#   ssh(fio_run("1M","read","1")) 
#   ssh(sync)
#   ssh(dd_run("1M","read"))

#   ssh(sync)
#   ssh(fio_run("4K","write","1"))
#   md5_test() 
#   ssh(sync)
#   ssh(fio_run("1M","write","1"))
#   md5_test()
