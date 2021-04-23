#/usr/bin/env python3
# coding=utf-8
import re
import threading
import argparse
import subprocess
import paramiko
import traceback
from time import ctime
#from queue import Queue
from optparse import OptionParser
from argparse import ArgumentParser
import sys


#HOST = ["10.16.45.11","10.16.45.12"]

def multi_threads(func, ips):
    threads = []
    for ip in ips:
        tid = threading.Thread(name='func', target=func, args=(ip, cmd))
        threads.append(tid)

    for tid in threads:
        tid.start()
    for tid in threads:
        tid.join()

def exc_cmd(cmd, stderr=False):
    re = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    p.wait()
    err = re.stderr.read().strip()
    out = re.stdout.read().strip()
    stat = re.returncode() 

    if stat == 0:
        return stat, out 
    else:
        return stat, err 

def ssh2(ip, cmd):
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(ip,22,"root",PASSWORD,timeout=50)
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

def install():
   ipmi_addrs = ["10.16.2.6","10.16.2.7","10.16.2.8","10.16.2.9"] 
   ips = ["10.16.2.6","10.16.2.7","10.16.2.8","10.16.2.9"] 
   for ipmi_ip in ipmi_addrs:
        exc_cmd("ipmitool -H {0} -U ADMIN -P ADMIN chassis bootdev pxe && ipmitool -H {0} -U ADMIN -P ADMIN power \
              reset".format(ipmi_ip))
   for hostip in ips:  
        try:
	        stat, _ = ssh2(ip,"uname -a")
        except Exception as e:
            print(ctime() + "connect host ip %s failed." % hostip)
            print(traceback.print_exc(e))

def yrfs_update(config="reboot"):

    start = ["systemctl daemon-reload","systemctl start yrfs-mgmtd","systemctl start yrfs-storage","systemctl start yrfs-admon","systemctl start yrfs-client"]
    stop = ["systemctl daemon-reload","systemctl stop yrfs-client","systemctl stop yrfs-mgmtd","systemctl stop yrfs-storage","systemctl stop yrfs-admon"]

    update_yum = ["yum clean","yum makecache","rpm -qa|grep -E \"yrfs|yanrong\"|xargs yum -y update"]
    update_client = ["systemctl stop yrfs-client","yum clean;yum makecache","rpm -qa|grep -E \"yrfs|yanrong\"|xargs yum -y update","systemctl daemon-reload","systemctl start yrfs-client"]

    clean_etcd = "etcdctl del /yrcf/mgmt/datadir/meta.nodes;etcdctl del /yrcf/mgmt/datadir/storage.nodes;etcdctl del /yrcf/mgmt/datadir/client.nodes"

    client_ver = ['grep "yrfs client version" /var/log/messages|tail -n 1']
    storage_ver = ['grep Version /var/log/yrfs-storage.log |tail -n 1']
    meta_ver = ['grep Version /var/log/yrfs-meta@mds*.log|tail -n 1']
    mgmt_ver = ['grep Version /var/log/yrfs-mgmtd.log|tail -n 1']

    one_meta_ip = SERVER[0] 
    meta_nums_cmd = "ps axu|grep -E \"yrfs-meta|yrfs-mds\"|grep -v grep|wc -l"
    #yrfs_version_cmd = "rpm -qa|grep yrfs|grep -w 6.3"
    yrfs_version_cmd = "yrcli --version"

    _, meta_nums = ssh2(one_meta_ip, meta_nums_cmd)

    version_stat, version_res = ssh2(one_meta_ip, yrfs_version_cmd)
    if version_stat == 0:
        version_res_tmp = re.findall("Version:(.*)",version_res)
        version_res = ''.join(version_res_tmp)[:3]

    else:
        yrfs_version_cmd = "rpm -qa|grep yrfs-client|awk -F '-' '{print $3}'|awk -F '.' '{print $1$2}'"
        version_stat, version_res = ssh2(one_meta_ip, yrfs_version_cmd)
        assert version_stat == 0, "no yrfs version found."
        version_res = ".".join(version_res)


    meta_service_cmd = ""
    print(version_res)
 
    if meta_nums == '1':

        if version_res == "6.3":
            repo_bak = ['mkdir -p /etc/yum.repos.d/cy_bak','mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/cy_bak','echo -e "[yrcf-6.4]\nname=yrcf-6.4\nenabled=1\nbaseurl=http://10.16.0.22:17285\ngpgcheck=0" > /etc/yum.repos.d/yrcf.repo']
            meta_service_cmd = "yrfs-meta.service"
        elif version_res == "6.5":
            repo_bak = ['mkdir -p /etc/yum.repos.d/cy_bak','mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/cy_bak','echo -e "[yrcf-6.4]\nname=yrcf-6.4\nenabled=1\nbaseurl=http://10.16.0.22:17283\ngpgcheck=0" > /etc/yum.repos.d/yrcf.repo']
            meta_service_cmd = "yrfs-meta.service"
        elif version_res == "6.6":
            repo_bak = ['mkdir -p /etc/yum.repos.d/cy_bak','mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/cy_bak','echo -e "[yrcf-6.4]\nname=yrcf-6.4\nenabled=1\nbaseurl=http://10.16.0.22:17284\ngpgcheck=0" > /etc/yum.repos.d/yrcf.repo']
            meta_service_cmd = "yrfs-mds@mds0.service"
        else:
            print("no matching version!")
 
    else:

        if version_res == "6.3":
            repo_bak = ['mkdir -p /etc/yum.repos.d/cy_bak','mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/cy_bak','echo -e "[yrcf-6.4]\nname=yrcf-6.4\nenabled=1\nbaseurl=http://10.16.0.22:17285\ngpgcheck=0" > /etc/yum.repos.d/yrcf.repo']
            meta_service_cmd = "yrfs-meta@mds0.service yrfs-meta@mds1.service"
        elif version_res == "6.5":
            repo_bak = ['mkdir -p /etc/yum.repos.d/cy_bak','mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/cy_bak','echo -e "[yrcf-6.4]\nname=yrcf-6.4\nenabled=1\nbaseurl=http://10.16.0.22:17283\ngpgcheck=0" > /etc/yum.repos.d/yrcf.repo']
            meta_service_cmd = "yrfs-meta@mds0.service yrfs-meta@mds1.service"
        elif version_res == "6.6":
            repo_bak = ['mkdir -p /etc/yum.repos.d/cy_bak','mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/cy_bak','echo -e "[yrcf-6.4]\nname=yrcf-6.4\nenabled=1\nbaseurl=http://10.16.0.22:17284\ngpgcheck=0" > /etc/yum.repos.d/yrcf.repo']
            meta_service_cmd = "yrfs-mds@mds0.service yrfs-mds@mds1.service"

    if version_res == "6.6":

        start = ["systemctl daemon-reload","systemctl start yrfs-mgr","systemctl start yrfs-oss","systemctl start yrfs-agent","systemctl start yrfs-client"]
        stop = ["systemctl daemon-reload","systemctl stop yrfs-client","systemctl stop yrfs-mgr","systemctl stop yrfs-oss","systemctl stop yrfs-agent"]
        client_ver = ['grep "yrfs client version" /var/log/messages|tail -n 1']
        storage_ver = ['grep Version /var/log/yrfs-oss.log |tail -n 1']
        meta_ver = ['grep Version /var/log/yrfs-mds@mds*.log|tail -n 1']
        mgmt_ver = ['grep Version /var/log/yrfs-mgr.log|tail -n 1']

    if version_stat == 0: 

        meta_start_cmd = "systemctl start " + meta_service_cmd
        meta_stop_cmd = "systemctl stop " + meta_service_cmd

        start.insert(2,meta_start_cmd)
        stop.insert(2,meta_stop_cmd)

        check_update_version = storage_ver + meta_ver + mgmt_ver + client_ver 

        server_update_cmd = repo_bak + stop + update_yum + start + check_update_version 
        client_update_cmd = repo_bak + update_client + client_ver 


    else:

        server_update_cmd = repo_bak + update_yum
        client_update_cmd = repo_bak + update_client

    if config == "reboot": 
        print(ctime() + '\033\treboot service.\n\033[0m')
        reboot_server = stop + start
        reboot_client = ["systemctl daemon-reload","systemctl stop yrfs-client","systemctl start yrfs-client"]

        return(reboot_server, reboot_client)

    else:
        print(ctime() + '\033\tupdate yrfs service.\n\033[0m')
        return(server_update_cmd, client_update_cmd)


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
    SERVER = ["10.16.2.11","10.16.2.12","10.16.2.13","10.16.2.14"]
    CLIENT = ["10.16.2.18"]

    #SERVER = ["192.168.12.66","192.168.12.69","192.168.12.70","192.168.12.71","192.168.12.72","192.168.12.73","192.168.12.74","192.168.12.75"]
    #CLIENT = ["192.168.12.90","192.168.12.91","192.168.12.92","192.168.12.93","192.168.12.94","192.168.12.95","192.168.12.96","192.168.12.98"]
    #SERVER = ["10.16.12.6","10.16.12.7","10.16.12.8","10.16.12.9"]
    #CLIENT = ["10.16.14.71","10.16.14.72"]

    #SERVER = ["10.16.15.122","10.16.15.225","10.16.15.227","10.16.15.229"]
    #CLIENT = ["10.16.15.250"]

    #SERVER = ["10.16.15.121","10.16.15.123","10.16.15.125","10.16.15.126"]
    #CLIENT = ["10.16.15.250"]

    #SERVER = ["10.16.15.121","10.16.15.123","10.16.15.125","10.16.15.126"]
    #CLIENT = ["10.16.15.250"]

    #SERVER = ["10.16.15.101","10.16.15.102","10.16.15.103","10.16.15.104"]
    #CLIENT = ["10.16.15.105"]

    #SERVER = ["10.16.15.11","10.16.15.12","10.16.15.13","10.16.15.14"]
    #CLIENT = ["10.16.15.15"]



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

        reboot_server, reboot_client = yrfs_update(config="reboot")

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
        server_update_cmd, client_update_cmd = yrfs_update(config="update")
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
