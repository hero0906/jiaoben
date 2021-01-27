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
from argparse import ArgumentParser
import sys


#HOST = ["192.168.45.11","192.168.45.12"]

def multi_threads(func, ips):
    threads = []
    for ip in ips:
        tid = threading.Thread(name='func', target=func, args=(ip, cmd))
        threads.append(tid)

    for tid in threads:
        tid.start()
    #for tid in threads:
    for tid in threads:
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
        stdin,stdout,stderr = ssh.exec_command(cmd)
    
        result = stdout.read().decode().rstrip("\n").lstrip("\n")
        err_result = stderr.read().decode().rstrip("\n").lstrip("\n")
        status = stdout.channel.recv_exit_status()

        if result:
            print(ctime() + '| [%s] connect OK! \033[34m[COMMAND:] %s, [OUTPUT:] %s\033[0m' % (ip, cmd, result.strip("\n")))
            return (status, result)
        elif err_result:
            print(ctime() + '| [%s] connect OK! \033[35m[COMMAND:] %s, [ERROR OUTPUT:] %s\033[0m' % (ip, cmd, err_result.strip("\n")))
            return (status, err_result)
        else:
            print(ctime() + '| [%s] connect OK! \033[34m[COMMAND:] %s\033[0m' % (ip, cmd))
            return (status, None)

    except Exception as e:
        print(ctime() + '\033[35m%s\t connect Error,\n\033[0m' % (ip))
        traceback.print_exc()
    finally:
        ssh.close()

if __name__ == '__main__':


    parser = OptionParser(description="upadate yrfs version", usage="%prog [-t] <server|client|all> -c <command>", version="%prog 1.0")
    parser.add_option('-t', '--type', dest='type', type='string', help="server type to update")
    parser.add_option('-r', '--reboot', action="store_true", dest="reboot", help="reboot service")
    parser.add_option('-c', '--command', dest='command', type='string',  help="linux shell command")
    options ,args = parser.parse_args(args=sys.argv[1:])
    print(options, args)

    assert options.type, "please enter the server type!!!"
    if options.type not in ('server', 'client', 'all'):
        raise ValueError
    #for cmd in (stop,update,start):


    PASSWORD = "Passw0rd"
    #SERVER = ["192.168.45.11","192.168.45.12","192.168.45.13","192.168.45.14"]
    #CLIENT = ["192.168.48.17","192.168.48.18"]

    SERVER = ["192.168.14.32","192.168.14.36","192.168.14.37","192.168.14.38"]
    CLIENT = ["192.168.14.71","192.168.14.72"]

    #SERVER = ["192.168.15.121","192.168.15.123","192.168.15.125","192.168.15.126"]
    #CLIENT = ["192.168.15.250"]

    #SERVER = ["192.168.15.101","192.168.15.102","192.168.15.103","192.168.15.104"]
    #CLIENT = ["192.168.15.105"]

    start = ["systemctl daemon-reload","systemctl start yrfs-mgmtd","systemctl start yrfs-storage","systemctl start yrfs-client"]
    stop = ["systemctl stop yrfs-client","systemctl stop yrfs-mgmtd","systemctl stop yrfs-storage"]

    update_yum = ["yum clean","yum makecache","yum -y update"]
    update_client = ["systemctl stop yrfs-client","yum clean;yum makecache","yum -y update","systemctl daemon-reload","systemctl start yrfs-client"]

    clean_etcd = "etcdctl del /yrcf/mgmt/datadir/meta.nodes;etcdctl del /yrcf/mgmt/datadir/storage.nodes;etcdctl del /yrcf/mgmt/datadir/client.nodes"

    client_ver = ['grep "yrfs client version" /var/log/messages|tail -n 1']
    storage_ver = ['grep Version /var/log/yrfs-storage.log |tail -n 1']
    meta_ver = ['grep Version /var/log/yrfs-meta@mds*.log|tail -n 1']
    mgmt_ver = ['grep Version /var/log/yrfs-mgmtd.log|tail -n 1']

    one_meta_ip = SERVER[0] 
    meta_nums_cmd = "ps axu|grep yrfs-meta|grep -v grep|wc -l"
    yrfs_version_cmd = "rpm -qa|grep yrfs|grep 6.3"

    _, meta_nums = ssh2(one_meta_ip, meta_nums_cmd)
    version_stat, version_res = ssh2(one_meta_ip, yrfs_version_cmd)
 
    if meta_nums == '1':
        if version_stat == 0:
            repo_bak = ['mkdir -p /etc/yum.repos.d/cy_bak','mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/cy_bak','echo -e "[yrcf-6.4]\nname=yrcf-6.4\nenabled=1\nbaseurl=http://192.168.0.22:17285\ngpgcheck=0" > /etc/yum.repos.d/yrcf.repo']
            meta_service_cmd = "systemctl start yrfs-meta@mds.service"
        else:
            repo_bak = ['mkdir -p /etc/yum.repos.d/cy_bak','mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/cy_bak','echo -e "[yrcf-6.4]\nname=yrcf-6.4\nenabled=1\nbaseurl=http://192.168.0.22:17283\ngpgcheck=0" > /etc/yum.repos.d/yrcf.repo']
            meta_service_cmd = "systemctl start yrfs-meta@mds0.service"
    else:
        meta_service_cmd = "systemctl start yrfs-meta@mds0.service yrfs-meta@mds1.service"
        if version_stat == 0:
            repo_bak = ['mkdir -p /etc/yum.repos.d/cy_bak','mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/cy_bak','echo -e "[yrcf-6.4]\nname=yrcf-6.4\nenabled=1\nbaseurl=http://192.168.0.22:17285\ngpgcheck=0" > /etc/yum.repos.d/yrcf.repo']
        else:
            repo_bak = ['mkdir -p /etc/yum.repos.d/cy_bak','mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/cy_bak','echo -e "[yrcf-6.4]\nname=yrcf-6.4\nenabled=1\nbaseurl=http://192.168.0.22:17283\ngpgcheck=0" > /etc/yum.repos.d/yrcf.repo']

    start.insert(2,meta_service_cmd)
    stop.insert(2,meta_service_cmd)

    check_update_version = storage_ver + meta_ver + mgmt_ver + client_ver 

    server_update_cmd = repo_bak + stop + update_yum + start + check_update_version 
    client_update_cmd = repo_bak + update_client + client_ver 

    reboot_server = stop + start
    reboot_client = ["systemctl stop yrfs-client","systemctl start yrfs-client"]

    if options.command:
        cmd = options.command
        if options.type == "client":
                multi_threads(ssh2, CLIENT)
        if options.type == "server":
                multi_threads(ssh2, SERVER)
        if options.type == "all":
                HOST = SERVER + CLIENT
                multi_threads(ssh2, HOST)

    elif options.reboot: 
        if options.type == "client":
            for cmd in reboot_client:
                multi_threads(ssh2, CLIENT)
        if options.type == "server":
            for cmd in reboot_server:
                multi_threads(ssh2, SERVER)
        if options.type == "all":
            for cmd in reboot_server:
                multi_threads(ssh2, SERVER)
            for cmd in reboot_client:
                multi_threads(ssh2, CLIENT)
    else:
        if options.type == "client":
            for cmd in client_update_cmd:
                multi_threads(ssh2, CLIENT)
        if options.type == "server":
            for cmd in server_update_cmd:
                multi_threads(ssh2, SERVER)
        if options.type == "all":
            for cmd in server_update_cmd:
                multi_threads(ssh2, SERVER)
            for cmd in client_update_cmd:
                multi_threads(ssh2, CLIENT)
