#/usr/bin/env python3
# coding=utf-8
import re
import threading
import argparse
import subprocess
import paramiko
import traceback
from time import ctime
from queue import Queue
from optparse import OptionParser
import sys


#HOST = ["192.168.45.11","192.168.45.12"]

class Worker(threading.Thread):
    def __init__(self, work_queue, result_queue):
        threading.Thread.__init__(self)
        self.work_queue = work_queue
        self.result_queue = result_queue
        self.start()

    def run(self):
        while True:
            func, arg, code_index = self.work_queue.get()
            res = func(args, code_index)
            self.result_queue.put(res)
            if self.result_queue.full():
                res = sorted([self.result_queue.get() for i in range(self.result_queue.qsize())], key=lambda s: s[0],
                        reverse=True)
                for obj in res:
                        print(obj)
            self.work_queue.task_done()

class MyQueue(object):
    def __init__(self, func, ip, thread_num):
        self.ip = ip
        self.func = func
        self.work_queue = Queue()
        self.threads = []
        self.__init__thread_poll(thread_num)

    def __init__thread_poll(self, thread_num):
        self.params = self.ip
        self.result_queue = Queue(maxsize=len(self.ip))
        for i in range(thread_num):
            self.threads.append(Worker(self.work_queue, self.result_queue))

    def del_params(self):
        for obj in self.params:
            self.work_queue.put(self.func)

    def wait_all_complete(self):
        for thread in self.threads:
            if thread.isAlive():
                thread.join

def multi_threads(func, ips):
    threads = []
    for ip in ips:
        tid = threading.Thread(name='func', target=func, args=(ip, cmd))
        tid.start()
        threads.append(tid)
    #for tid in threads:
    tid.join()

def exc_cmd(cmd, stderr=False):
    re = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    if stderr:
        return re.stdout.read().strip(), re.stderr.read().strip()
    else:
        return re.stdout.read().strip()

def ssh2(ip, cmd):
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(ip,22,"root",PASSWORD,timeout=5)
        stdin,stdout,stedrr = ssh.exec_command(cmd)
        if stdout:
            print(ctime() + '%s\tconnect OK, \nCOMMAND:\t%s \nOUTPUT:\t%s\n'%(ip, cmd, stdout.readlines()))
    except Exception as e:
        print(ctime() + '%s\t connect Error,\n' % (ip))
        traceback.print_exc()
    finally:
        ssh.close()

if __name__ == '__main__':

    PASSWORD = "Passw0rd"

    #SERVER = ["192.168.45.11","192.168.45.12","192.168.45.13","192.168.45.14"]
    #CLIENT = ["192.168.48.17","192.168.48.18"]

    SERVER = ["192.168.14.32","192.168.14.36","192.168.14.37","192.168.14.38"]
    CLIENT = ["192.168.14.71","192.168.14.72"]
    #SERVER = ["192.168.15.121","192.168.15.123","192.168.15.125","192.168.15.126"]
    #CLIENT = ["192.168.15.250"]

    #SERVER = ["192.168.15.101","192.168.15.102","192.168.15.103","192.168.15.104"]
    #CLIENT = ["192.168.15.105"]

    start = "systemctl daemon-reload;systemctl start yrfs-mgmtd;systemctl start yrfs-meta@mds0.service yrfs-meta@mds1.service;systemctl start yrfs-storage;systemctl start yrfs-client"
    stop = "systemctl stop yrfs-client;systemctl stop yrfs-mgmtd;systemctl stop yrfs-meta@mds0.service yrfs-meta@mds1.service;systemctl stop yrfs-storage"
    update = "yum clean;yum makecache;yum -y update"
    update_client = "systemctl stop yrfs-client;yum clean;yum makecache;yum -y update;systemctl daemon-reload;systemctl start yrfs-client"

    clean_etcd = "etcdctl del /yrcf/mgmt/datadir/meta.nodes;etcdctl del /yrcf/mgmt/datadir/storage.nodes;etcdctl del /yrcf/mgmt/datadir/client.nodes"

    #repo_bak = 'mkdir -p /etc/yum.repos.d/bak;mv /etc/yum.repos.d/* /etc/yum.repos.d/bak;echo -e "[yrcf-6.4]\nname=yrcf-6.4\nenabled=1\nbaseurl=http://192.168.0.22:17283\ngpgcheck=0" > /etc/yum.repos.d/yrcf.repo'
    repo_bak = 'mkdir -p /etc/yum.repos.d/bak;mv /etc/yum.repos.d/* /etc/yum.repos.d/bak;echo -e "[yrcf-6.4]\nname=yrcf-6.4\nenabled=1\nbaseurl=http://192.168.0.22:17285\ngpgcheck=0" > /etc/yum.repos.d/yrcf.repo'
    client_ver = ('grep "yrfs client version" /var/log/messages|tail -n 1',)
    storage_ver = ('grep Version /var/log/yrfs-storage.log |tail -n 1',)
    meta_ver = ('grep Version /var/log/yrfs-meta@mds*.log|tail -n 1',)

    parser = OptionParser(description="upadate yrfs version", usage="%prog [-t] <server|client|all> -c <command>", version="%prog 1.0")
    parser.add_option('-t', '--type', dest='type', type='string', help="server type to update")
    parser.add_option('-c', '--command', dest='command', type='string',  help="linux shell command")
    options ,args = parser.parse_args(args=sys.argv[1:])

    assert options.type, "please enter the server type!!!"
    if options.type not in ('server', 'client', 'all'):
        raise ValueError
    #for cmd in (stop,update,start):

    if options.command:
        cmd = options.command
        if options.type == "client":
                multi_threads(ssh2, CLIENT)
        if options.type == "server":
                multi_threads(ssh2, SERVER)
        if options.type == "all":
                HOST = SERVER + CLIENT
                multi_threads(ssh2, HOST)

    else: 
        if options.type == "client":
            for cmd in (repo_bak,update_client,):
                multi_threads(ssh2, CLIENT)
        if options.type == "server":
            for cmd in (repo_bak,stop,update,start):
                multi_threads(ssh2, SERVER)
        if options.type == "all":
            for cmd in (repo_bak,stop,update,start):
                multi_threads(ssh2, SERVER)
            for cmd in (repo_bak,update_client,):
                multi_threads(ssh2, CLIENT)
