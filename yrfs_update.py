#!env /usr/bin/python3
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
    SERVER = ["192.168.45.11","192.168.45.12","192.168.45.13","192.168.45.14"]
    CLIENT = ["192.168.48.17","192.168.48.18"]

    start = "systemctl daemon-reload;systemctl start yrfs-mgmtd;systemctl start yrfs-meta@mds0.service;\
            systemctl start yrfs-storage;systemctl start yrfs-client"
    stop = "systemctl daemon-reload;systemctl stop yrfs-client;systemctl stop yrfs-mgmtd;\
            systemctl stop yrfs-meta@mds0.service;systemctl stop yrfs-storage"
    update = "yum clean;yum makecache;yum -y update"
    etcd = "etcdctl del /yrcf/mgmt/datadir/meta.nodes;etcdctl del /yrcf/mgmt/datadir/storage.nodes;etcdctl del /yrcf/mgmt/datadir/client.nodes"
    update_client = "systemctl stop yrfs-client;yum clean;yum makecache;yum -y update;systemctl daemon-reload;systemctl start yrfs-client"

    parser = OptionParser(description="upadate yrfs version", usage="%prog [-t] <server|client|all>", version="%prog 1.0")
    parser.add_option('-t', '--type', dest='type', type='string', help="server type to update")
    options ,args = parser.parse_args(args=sys.argv[1:])

    assert options.type, "please enter the server type!!!"
    if options.type not in ('server', 'client', 'all'):
        raise ValueError
    #for cmd in (stop,update,start):
    if options.type == "client":
        for cmd in (update_client,):
            multi_threads(ssh2, CLIENT)
    if options.type == "server":
        for cmd in (stop,update,start):
            multi_threads(ssh2, SERVER)
    if options.type == "all":
        for cmd in (stop,update,start):
            multi_threads(ssh2, SERVER)
        for cmd in (update_client,):
            multi_threads(ssh2, CLIENT)
