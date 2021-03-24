#coding=utf-8
import os
import threading
from time import ctime
import os
from pathlib import Path
import base64
import random
import uuid


def t1(filename):
    Path(filename).touch()


def run(loop):
    num = 0
    ft = "/mnt/yrfs/%s" % (str(uuid.uuid4()))
    Path(ft).mkdir()
    while True:
        threads = []
        for i in range(20):
            name = str(uuid.uuid4())
            filename = os.path.join(ft,name*random.randint(1,6))

            thread1 = threading.Thread(target=t1,args=(filename,))  
            threads.append(thread1)
        
        for t in threads:
            t.start()
        
        for t in threads:
            t.join()

        num = num + 20
        print(ctime() + "|\tloops %s, dir %s, files nums: %s " %(str(loop), ft, str(num)))

        if num == 10000000:
            return


while True:
    loop = 1
    run(loop)
    loop = loop + 1

#for i in range(100000):
#    run()
#while True:
#    test()
#    num += 1
#    print("open close test times : %s" % num)

