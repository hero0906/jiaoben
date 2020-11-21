#!/usr/bin/python
# coding=utf-8
import re
import threading
import argparse
import subprocess
import paramiko


HOST = ["192.168.45.11","192.168.45.12","192.168.45.13","192.168.45.14"]


def multi_threads(func):
    threads = []
    for ip in HOST:
        tid = threading.Thread(name='func', target=func, args=(ip,))
        tid.start()
        threads.append(tid)
        for tid in threads:
            tid.join()

def exc_cmd(cmd, stderr=False):
    re = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    if stderr:
        return re.stdout.read().strip(), re.stderr.read().strip()
    else:
        return re.stdout.read().strip()

def ssh2():
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(ip,22,"root","password",timeout=5)
        stdin,stdout,stedrr = ssh.exec_command(cmd)
        if stdout:
            print('%s\tOK, output: %s\n'%(ip, stdout.readlines()))
    except Exception as e:
	    print('%s\tError,e\n'%(ip, e))
    finally:
    	ssh.close()

if __name__ == '__main__':
    cmd = "ls /root"
    multi_threads(ssh2())
