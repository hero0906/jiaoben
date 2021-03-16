#!/usr/bin/env python
# -*- coding:utf-8 -*-

import logging
import os
import subprocess
import random
from time import ctime,sleep


class logger(object):
    """
    终端打印不同颜色的日志，在pycharm中如果强行规定了日志的颜色， 这个方法不会起作用， 但是
    对于终端，这个方法是可以打印不同颜色的日志的。
    """

    # 在这里定义StreamHandler，可以实现单例， 所有的logger()共用一个StreamHandler
    ch = logging.StreamHandler()

    def __init__(self):
        self.logger = logging.getLogger()
        if not self.logger.handlers:
            # 如果self.logger没有handler， 就执行以下代码添加handler
            self.logger.setLevel(logging.DEBUG)
            #from serviceProgram.utils.FileUtil import FileUtil
            #rootPath = FileUtil.getProgrameRootPath()
            self.log_path = 'logs/'
            if not os.path.exists(self.log_path):
                os.makedirs(self.log_path)

            # 创建一个handler,用于写入日志文件
            fh = logging.FileHandler(self.log_path + '/runlog.log',
                                     encoding='utf-8')
            fh.setLevel(logging.INFO)

            # 定义handler的输出格式
            formatter = logging.Formatter('[%(asctime)s] - [%(levelname)s] - %(message)s')
            fh.setFormatter(formatter)

            # 给logger添加handler
            self.logger.addHandler(fh)

    def debug(self, message):
        self.fontColor('\033[0;32m%s\033[0m')
        self.logger.debug(message)

    def info(self, message):
        self.fontColor('\033[0;34m%s\033[0m')
        self.logger.info(message)

    def warning(self, message):
        self.fontColor('\033[0;37m%s\033[0m')
        self.logger.warning(message)

    def error(self, message):
        self.fontColor('\033[0;31m%s\033[0m')
        self.logger.error(message)

    def critical(self, message):
        self.fontColor('\033[0;35m%s\033[0m')
        self.logger.critical(message)

    def fontColor(self, color):
        # 不同的日志输出不同的颜色
        formatter = logging.Formatter(color % '[%(asctime)s] - [%(levelname)s] - %(message)s')
        self.ch.setFormatter(formatter)
        self.logger.addHandler(self.ch)

logger = logger()

def shell(cmd):

    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    p.wait()
    out = p.stdout.read().decode().strip()
    err = p.stderr.read().decode().strip()
    stat = p.returncode

    if stat == 0:
        logger.info("COMMAND:%s, success, RESULT:%s." % (cmd,out))
        return stat, out
    else:
        logger.error("COMMAND:%s, fail, RESULT:%s" % (cmd,err))
        return stat, err

def ssh(ip, cmd, username="root",password="PasswOrd"):
    try:
        con = paramiko.SSHClient()
        con.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        con.connect(ip, port=22, username=username, password=password)
        stdin, stdout, stderr = con.exec_command(cmd)

        result = stdout.read().decode().rstrip("\n").lstrip("\n")
        err_result = stderr.read().decode().rstrip("\n").lstrip("\n")
        status = stdout.channel.recv_exit_status()

        if result:
            logger.info("host: %s, command: %s, success, result:\n%s" % (self.ip, cmd, result.strip("\n")))
            return (status, result)
        elif err_result:
            if status == 0:
                logger.info("host: %s, command: %s, success, result:\n%s" % (self.ip, cmd, err_result.strip("\n")))
                return (status, err_result)
            else:
                logger.info("host: %s, command: %s, failed, result:\n%s" % (self.ip, cmd, err_result.strip("\n")))
                return (status, err_result)
        else:
            if status == 0:
                logger.info("host: %s, command: %s success." % (self.ip, cmd))
                return (status, None)
            else:
                logger.error("host: %s, command: %s failed." % (self.ip, cmd))
                return (status, None)

    except Exception as e:
        logger.error(traceback.format_exc())
    finally:
        con.close()


def test_disk_plug():

    bcache_stat, _ = shell("lsblk |grep bcache")
    if bcache_stat == 0:
        logger.error("test not suport bcache environment and will exit. bye!")
        exit()
    else:
        logger.info("disk plug test runing.")

    _, df_disk_tmp = shell("df -h|grep oss")
    one_disk_tmp = random.choice(df_disk_tmp.split("\n"))

    disk_path = one_disk_tmp.split()[0]
    disk_name = disk_path.split("/")[2]
    disk_mount_point = one_disk_tmp.split()[5]
    _, target_id = shell("cat %s/targetid" % disk_mount_point)
    _, node_id = shell("cat %s/nodeid" % disk_mount_point)
    _, node_name = shell("cat %s/nodename" % disk_mount_point)
    _, mgmt_hosts = shell("cat /etc/yrfs/yrfs-client.conf |awk NR==1'{print $3}'")

    stat_pull, _ = shell("echo offline >/sys/block/{0}/device/state;echo 1 >/sys/block/{0}/device/delete".format(disk_name))
    assert stat_pull == 0, "disk pull failed."

    sleep(5)
    stat_insert, disk_insert = shell("echo \"- - -\" > /sys/class/scsi_host/host0/scan")
    assert stat_insert == 0, "disk insert failed"

    #查询osd是否呈现为dirty状态
    shell("yrcli --osd|grep dirty")

    #等待三十秒后改osd的state变为down
    sleep(30)
    down_osd_stat, _ = shell("yrcli --downosd --osdid=%s" % target_id)
    assert down_osd_stat == 0, "downosd failed."
    sleep(5)
    #卸载磁盘挂载点
    for num in range(5):
        umount_stat, _ = shell("umount " + disk_mount_point)
        if umount_stat == 0:
            break
        else:
            logger.info("unmount %s times: %s" % (disk_mount_point, num))
            sleep(2)
            continue
    assert umount_stat == 0, "umount disk failed."
    #查询新盘的盘符
    _, new_disk_name = shell("cat /proc/partitions|grep -v bcache|tail -n 1|awk '{print $4}'")
    #格式化新磁盘
    mkfs_stat, _ = shell("mkfs.xfs -d su=128k,sw=8 -l version=2,su=128k -isize=512 -f %s" % new_disk_name)
    assert mkfs_stat == 0, "mkfs disk failed."
    #替换磁盘fstab uuid
    shell("sed \"s#^.*%s#`blkid /dev/%s|awk '{print $2}'` %s#\" /etc/fstab" % (disk_mount_point,new_disk_name,disk_mount_point))
    #新磁盘挂载
    shell("systemctl daemon-reload")
    mount_stat, _ = shell("mount -a")
    assert mount_stat == 0, "disk mount failed."
    #磁盘初始化
    oss_init_stat, _ = shell("/usr/local/sbin/yrfs-setup-storage -p {0} -S {1} \
    -s {2} -i {3} -I tg{3} -z 0 -m {4}".format(disk_mount_point,node_name,node_id,target_id,mgmt_hosts))
    assert oss_init_stat == 0, "oss init failed."
    #上线磁盘
    up_osd_stat, _ = shell("yrcli --uposd --osdid=%s" % target_id)
    assert up_osd_stat == 0, "up osd failed."
    sleep(20)
    #触发全量恢复
    rebuild_stat, _ = shell("yrcli --osd|grep %s|grep rebuild" % target_id)
    assert rebuild_stat == 0, "osd not rebuild."
    no_rebuild_stat, _ = shell("yrcli --osd|grep -v %s|grep rebuild" % target_id)
    assert no_rebuild_stat != 0, "other osd rebuild."

    while True:
        rebuild_stat, _ = shell("yrcli --osd|grep %s|grep rebuild" % target_id)
        sleep(5)
        if rebuild_stat != 0:
            logger("info","osd rebuild over.")
            break
    logger("info","Congratulations.test passed!!!")


def test_disk_scale():
    remote_host = "192.168.14.25"
    local_disk = "/dev/sdb"
    remote_disk = "/dev/sdc"
    #磁盘格式化
    mkfs_cmd = "mkfs.xfs -d su=128k,sw=8 -l version=2,su=128k -isize=512 -f "
    mkfs_local_stat, _ = shell(mkfs_cmd + local_disk)
    mkfs_remote_stat, _ = ssh(remote_host, mkfs_cmd + remote_disk)
    assert mkfs_local_stat == 0 or mkfs_remote_stat == 0, "mkfs failed."
    #添加uuid到fstab中
    _, local_oss_num = shell("cat /etc/fstab|grep oss|wc -l")
    _, remote_oss_num = ssh(remote_host,"cat /etc/fstab|grep oss|wc -l")
    local_oss_id = int(local_oss_num) + 1
    remote_oss_id = int(remote_oss_num) + 1
    local_mount_dir = "/data/oss" + str(local_oss_id)
    remote_mount_dir = "/data/oss" + str(remote_oss_id)

    shell("echo \"`blkid %s|awk '{print $2}'` %s xfs     defaults,prjquota,allocsize=8M,noatime,nodiratime,\
    logbufs=8,logbsize=256k,largeio,inode64,swalloc,nofail,x-systemd.device-timeout=5 0 0\" >> /etc/fstab" % (local_disk,local_mount_dir))
    ssh(remote_host, "echo \"`blkid %s|awk '{print $2}'` %s xfs     defaults,prjquota,allocsize=8M,noatime,nodiratime,\
    logbufs=8,logbsize=256k,largeio,inode64,swalloc,nofail,x-systemd.device-timeout=5 0 0\" >> /etc/fstab" % (remote_disk,remote_mount_dir))
    #磁盘挂载
    mount_local_stat, _ = shell("mkdir -p %s;systemctl daemon-reload;mount -a" % local_mount_dir)
    mount_remote_stat, _ = ssh(remote_host, "mkdir -p %s;systemctl daemon-reload;mount -a" % remote_mount_dir)
    assert mount_local_stat == 0 or mount_remote_stat == 0, "disk mount failed"
    #当前的oss个数和group组个数、mgmt信息
    _, local_nodeid = shell("cat /data/oss*/nodeid|uniq")
    _, remote_nodeid = ssh(remote_host,"cat /data/oss*/nodeid|uniq")
    _, local_hostname = shell("cat /data/oss*/nodename|uniq")
    _, remote_hostname = ssh(remote_host,"cat /data/oss*/nodename|uniq")

    _, local_max_targetid = shell("yrcli --osd |grep %s|tail -n 1|awk '{print $1}'" % local_nodeid)
    _, remote_max_targetid = ssh(remote_host,"yrcli --osd |grep %s|tail -n 1|awk '{print $1}'" % remote_nodeid)

    local_new_targetid = str(int(local_max_targetid) + 1)
    remote_new_targetid = str(int(remote_max_targetid) + 1)

    _, oss_group_id = shell("yrcli --group --type=oss|wc -l")
    _, mgmt_hosts = shell("cat /etc/yrfs/yrfs-client.conf |awk NR==1'{print $3}'")
    #初始化oss信息
    local_init_stat, _ = shell("/usr/local/sbin/yrfs-setup-storage -p {0} -S {1} -s 101 -i {2} -I tg{3} -z 0 \
    -m {4}".format(local_mount_dir,local_hostname,local_new_targetid,mgmt_hosts))
    remote_init_stat, _ = ssh(remote_host,"/usr/local/sbin/yrfs-setup-storage -p {0} -S {1} -s 101 -i {2} -I \
    tg{3} -z 0 -m {4}".format(remote_mount_dir,remote_hostname,remote_new_targetid,mgmt_hosts))

    assert local_init_stat == 0 or remote_init_stat == 0, "disk init setup failed."
    #加入oss到集群内
    local_add_stat, _ = shell("yrcli --addosd --nodeid=%s --osdpath=%s" % (local_nodeid,local_mount_dir))
    remote_add_stat, _ = ssh(remote_host,"yrcli --addosd --nodeid=%s --osdpath=%s" % (remote_nodeid,remote_mount_dir))
    assert local_add_stat == 0 or remote_add_stat == 0, "add osd failed."
    #添加分组
    add_group_stat,_ = shell("yrcli --addgroup --master=%s --slave=%s --groupid=%s --type=oss" % (local_new_targetid, remote_new_targetid,oss_group_id))
    assert add_group_stat == 0, "add group failed."
    #检验osd group组是否真实存在
    check_group_stat, check_group_stat = shell("yrcli --osd|awk '{print $3}'|grep %s|wc -l")
    assert check_group_stat == 2, "check group stat failed."

def test_disk_remove():
    #将要测试磁盘删除的磁盘
    test_disk = "/dev/sdc"
    #格式化新盘
    mkfs_stat, _ = shell("mkfs.xfs -d su=128k,sw=8 -l version=2,su=128k -isize=512 -f %s" % remove_disk)
    #添加磁盘的uuid到fatab中
    _, current_oss_num = shell("cat /etc/fstab|grep oss|wc -l")
    mount_dir = "/data/oss%s" % str(int(current_oss_num) + 1)
    shell("echo \"`blkid %s|awk '{print $2}'` %s xfs     defaults,prjquota,allocsize=8M,noatime,nodiratime,\
        logbufs=8,logbsize=256k,largeio,inode64,swalloc,nofail,x-systemd.device-timeout=5 0 0\" >> /etc/fstab" % (test_disk,mount_dir))
    #创建挂载目录并挂载
    shell("mkdir -p " + mount_dir)
    mount_stat, _ = shell("systemctl daemon-reload;mount -a")
    #设置oss属性值
    nodeid = shell("cat /data/oss*/nodeid|uniq")
    nodename = shell("cat /data/oss*/nodename|uniq")
    max_targetid = shell("yrcli --osd |grep %s|tail -n 1|awk '{print $1}'" % nodeid)
    new_targetid =  str(int(max_targetid) + 1)
    mgmt_hosts = shell("cat /etc/yrfs/yrfs-client.conf |awk NR==1'{print $3}'")
    oss_init_stat, _ = shell("/usr/local/sbin/yrfs-setup-storage -p {0} -S {1} -s 101 -i {2} -I tg{3} -z 0 \
        -m {4}".format(mount_dir, nodename, new_targetid, mgmt_hosts))
    assert oss_init_stat == 0, "setup oss attribute failed."
    #加入oss到集群
    add_osd_stat, _ = shell("yrcli --addosd --nodeid=%s --osdpath=%s" % (nodeid, mount_dir))
    assert add_osd_stat == 0, "add osd failed."
    #验证osd map是否存在该osd
    checK_oss_stat, _ = shell("yrcli --osd|grep %s" % new_targetid)
    assert check_oss_stat == 0, "osd not in group."
    #删除新加入的osd
    remove_oss_stat,_ = shell("yrcli --rmosd --osdid=%s" % new_targetid)
    check_remove_stat, _ = shell("yrcli --osd|grep %s" % new_targetid)
    assert remove_oss_stat == 0 or check_remove_stat != 0, "osd remove failed."
    #删除挂载信息
    shell("umount " + mount_dir)
    shell("sed -i \"s#,%s/##g\" /etc/yrfs/yrfs-storage.conf" % mount_dir)
    shell("rm -fr " + mount_dir)

test_disk_plug()
