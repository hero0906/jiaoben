#coding=utf-8
import os
import threading
import time
import os

ft = "/mnt/yrfs/test_file18"

def t1():
    os.stat(ft)
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()) + ": t1 stat")
    with open(ft, 'w+') as f:
    	f.write("生亦何欢，死又何惧。")
    f.close()
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()) + ": t1 write")
    #os.remove(ft)
    #print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()) + ": t1 remove")
    #print("close file " + time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()))

def t2():
    os.stat(ft)
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()) + ": t2 stat")

def t3():
    os.stat(ft)
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()) + ": t2 stat")

def run():

    os.system("touch %s" %ft)
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()) + ": touch file %s" % ft)

    threads = []
    
    for i in range(10):
    	thread1 = threading.Thread(target=t1,)  
    	thread2 = threading.Thread(target=t2,)  
    	thread3 = threading.Thread(target=t3,)  
    	threads.append(thread1)
    	threads.append(thread2)
    print(threads)
    
    for t in threads:
        t.start()
    
    for t in threads:
        t.join()

    os.system("echo %s" %ft)
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()) + ": echo file %s" % ft)

while True:
    run()

#for i in range(100000):
#    run()
#while True:
#    test()
#    num += 1
#    print("open close test times : %s" % num)

