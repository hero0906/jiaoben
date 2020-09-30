#coding=utf-8
#!/usr/bin/python

import sys
import os
import subprocess
import re
import logging
import time
import numpy
import random

dire = 'iops'
result = 'iops_all_data.log'
test_env = 'iops/iops_env'


class base_per():

    def __init__(self):
        #self.path = '/dev/nvme0n1'
        self.path = '/mnt/yrfs/qos/test_qos002000'
        self.con = 'test_path'

	self.rand_dis = 'random:3/zipf:4/pareto:5/normal:3/zoned:3/zoned_abs:5'
	self.loops = '100000'
	self.rand_gener = ("tausworthe","lfsr","tausworthe64","tausworthe")
	self.engine = ("sync","psync","vsync","pvsync","pvsync2","rdma","posixaio") 
	self.rw = "rw"
        
    def logger(self, loglevel, log):
        log_level = {
                'critical': logging.critical,
                'error': logging.error,
                'warning': logging.warning,
                'info': logging.info,
                'debug': logging.debug
                }
        logging.basicConfig(level=logging.DEBUG,  
                format='%(asctime)s %(filename)s[line:%(lineno)d] %(levelname)s %(message)s',  
                filename='iops/iops_log',  
                )  
        console = logging.StreamHandler()
        console.setLevel(logging.INFO)
        formatter = logging.Formatter('%(levelname)-8s %(asctime)-4s %(message)s')
        console.setFormatter(formatter)
        logging.getLogger('').addHandler(console)
        log_level[loglevel](log)
        logging.getLogger('').removeHandler(console)

    def execute(self, *args):
        name = args[0]
        cmd = args[1]
        start = name + ' is running....................'
        self.logger('info',start)
        self.logger('debug',cmd)
        try:
            p = subprocess.Popen(cmd,shell=True,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,close_fds=True)
            if len(args) >= 3:
                input = args[2]
                p.stdin.write(input)
            out,err = p.communicate()
            recode = p.returncode
#            if recode !=0 or len(err) != 0:
            if recode !=0:
                raise RuntimeError(err)
            else:
                over = name + ' is over!'
                self.logger('info',over)
        except Exception as e:
            self.logger('error', e)
            exit()
        return out 

    def low_format(self):
        cmd = './nvmemgr formatnvm --lbaformat=0 -c ' + self.con
        format = self.execute('format',cmd)
       
    def get_system(self):
        cmd = 'uname -r'
        kernel = self.execute('get kernel',cmd)
        kernel = kernel.strip('\n')
#        print 'kernel: ',kernel
        cmd = 'cat /etc/redhat-release'
        os = self.execute('get os',cmd)
        os = os.strip('\n')
#        print 'os: ',os
        cmd = "cat /proc/cpuinfo |grep processor |awk 'END{print $3}'"
        cpu_core = self.execute('get cpu core number',cmd)
        cpu_core = int(cpu_core.strip('\n')) + 1
#        print 'cpu core number =',cpu_core
        cmd = "cat /proc/cpuinfo |grep 'physical id' |awk 'END{print $4}'"
        cpu_num = self.execute('get cpu number',cmd)
        cpu_num = int(cpu_num.strip('\n')) + 1
#        print 'cpu number =',cpu_num
        cmd = "cat /proc/cpuinfo |grep 'model name' |awk 'END{print}'"
        cpu_model = self.execute('get cpu model',cmd)
        cpu_model = cpu_model.strip('\n')
        cpu_model = cpu_model[13:]
#        print 'cpu model =',cpu_model
        cmd = "cat /proc/meminfo |grep MemTotal |awk '{print $2 $3}'"
        memory_total = self.execute('get memory total',cmd)
        memory_total = memory_total.strip('\n')
#        print 'memory total =',memory_total
        cmd = "cat /proc/meminfo |grep MemFree |awk '{print $2 $3}'"
        memory_free = self.execute('get memory free',cmd)
        memory_free = memory_free.strip('\n')
#        print 'memory free =',memory_free
        system = 'Kernel: '+kernel+'\n' +'OS: '+os+'\n'+'CPU: '+cpu_model+'  '+str(cpu_num)+'*'+str(cpu_core/cpu_num)+'core \n'+'Memory total: '+memory_total+'\n'+'Memory free: '+memory_free
        return system
       
    def get_pblaze4(self):
        cmd = './nvmemgr identify -p -c ' + self.con + '|grep Mode'
        pn = self.execute('get pn',cmd)
        pn = pn.strip('\n')
        pn = pn[63:]
#        print 'pn =',pn
        cmd = './nvmemgr identify -p -c ' + self.con + '|grep Serial'
        sn = self.execute('get sn',cmd)
        sn = sn.strip('\n')
        sn = sn[63:]
#        print 'sn =',sn
        cmd = "modinfo nvme|grep version:|sed -n '1p'"
        driver = self.execute('get driver version',cmd)
        driver = driver.strip('\n')
        driver = driver[16:]
#        print 'driver version=',driver
        cmd = './nvmemgr identify -p -c ' + self.con + '|grep Revision'
        firmware = self.execute('get firmware version',cmd)
        firmware = firmware.strip('\n')
        firmware = firmware[63:]
#        print 'firmware version =',firmware
        pblaze4 = 'pn: '+pn+'\n'+'sn: '+sn+'\n'+'driver version: '+driver+'\n'+'firmware version: '+firmware
        return pblaze4
       
    def fio_output_iops(self,filename):
        iops = 0
        result_out = open(filename,'r')
        for eachline in result_out:
            iops0 = re.search(r'(?<=iops=)\d*', eachline)
            if iops0:
                iops0 = int(iops0.group())
                iops = iops + iops0
        result_out.close()
        return iops
    
    def steady_state(self,list):
        if len(list) < 5:
            rounds =  'The rounds is', len(list),'less than 5.'
            self.logger('info',rounds)
            return False
        else:
            y = list[-5:]
            y_avg = sum(y)/len(y)
            [p,s]=numpy.polyfit(range(1,6),y,1)
            range_y = (max(y) - min(y))*1.0/y_avg*100
            slope_y = abs(p)*4.0/y_avg*100
            rangey = 'Range(y) is '+str(range_y)+'% of Ave(y)(<20%)'
            slopey = 'Slope(y) is '+str(slope_y)+'% of Ave(y)(<10%)'
            self.logger('info',rangey)
            self.logger('info',slopey)
            if range_y < 20 and slope_y < 10:
                cmd = 'The '+str(len(list))+' rounds to reach steady state.' 
                self.logger('info',cmd)
                return True, [len(list)-4,len(list)-3,len(list)-2,len(list)-1,len(list)], y, y_avg, range_y, slope_y, p, s
                #len(list), y_avg, p, s
            else:
                cmd = str(len(list))+' rounds did not reach steady state.'
                self.logger('info',cmd)
                if len(list) == 25:
                    return False, [21,22,23,24,25], y, y_avg, range_y, slope_y, p, s
                else:
                    return False
        
    def gnuplot(self, dir, titles, ylabels, *args):
        options = 'set terminal png \n'+'set title \''+titles+'\'\n'+'set output \''+dir+'/'+titles+'.png\'\n'+"set xlabel 'Time(second)'\n set xtics 3600\n set mxtics 2\n"+'set ylabel \''+ylabels+'\''
        for element in args:
            options += '\n' + element
        cmd = 'echo \"\n' + options +'\n' +' \" | gnuplot'
#        print cmd
        self.execute('gnuplots',cmd)

        
        
base_p = base_per()
def test():
    #base_p.low_format()  #Purge the device.
    #fio = 'fio --ioengine=libaio --randrepeat=0 --norandommap --thread --direct=0 --name=init_seq --rw=write --bs=128k --output=iops/init_seq.log --iodepth=1 --loops=1 --filesize=10M --nrfiles=100 --numjobs=16 --directory=' + base_p.path
    #base_p.execute('init_seq ',fio)    #Run SEQ Workload Independent Preconditioning
    iops_gather = []
    for rounds in range(1,26):
        for mixread in['100','95','65','50','35','5','0']:
            for bs in ['1024k','128k','64k','32k','16k','8k','4k','512']:
                name = str(rounds) + '_' + mixread + '_'+bs
                output = dire + '/' + name+'.log'

   		fio = 'fio --group_reporting --ioengine={engine} --directory={testdir} --name={name} --blocksize_range={bs}\
 --sync=1 --numjobs=16 --size=10G --nrfiles=100 --eta-newline=1 --eta-interval=1 --rw_sequencer=sequential --rw={rw} --do_verify=1\
 --verify=crc32 --random_distribution={rand_dis} --rwmixwrite={rwmix} --randseed={randseed} --loops={loops} --output={output}\
 --percentage_random=50 --random_generator={rand_gener}'.\
		format(engine=random.choice(base_p.engine),testdir=base_p.path,rand_dis=base_p.rand_dis,randseed=random.randint(1,10000),\
		loops=base_p.loops,rand_gener=random.choice(base_p.rand_gener),rw=base_p.rw,name=name,output=output,rwmix=mixread,bs=str(random.randint(1,1024))+"k/50:"+bs+"/50")
		print fio

                time.sleep(5)
                base_p.execute(name,fio)
                time.sleep(5)
                if mixread == '0' and bs == '4k':
                    iops = base_p.fio_output_iops(output)
                    iops_gather.append(iops)
        ss = base_p.steady_state(iops_gather)
        if ss:
            f=open('iops_ssInfo.log','a')
            f.write('Steady State has been reached: '+str(ss[0])+'\n')
            f.write('Rounds: '+str(ss[1])+'\n')
            f.write('Values: '+str(ss[2])+'\n')
            f.write('Average: '+str(ss[3])+'\n')
            f.write('Range(<20%): '+str(ss[4])+'%\n')
            f.write('Slope(<10%): '+str(ss[5])+'%\n')
            f.write('Function for best linear fit: y='+str(ss[6])+'*x+'+str(ss[7])+'\n')
            f.close()
            for bs in ['512','4k','8k','16k','32k','64k','128k','1024k']:
                for num in range(1,rounds+1):
                    output = dire + '/' + str(num) + '_0_' + bs + '.log'
                    iops = base_p.fio_output_iops(output)
                    f=open('iops/iops_0_bs='+bs,'a')
                    f.write(str(num)+' '+str(iops)+'\n')
                    f.close()
            for num in range(rounds-4,rounds+1):
                f=open('iops/iops_0_bs=4k_value','a')
                f.write(str(num)+' '+str(ss[2][num-1])+'\n')
                f.close()
                f=open('iops/iops_0_bs=4k_slope','a')
                y = num * ss[6] + ss[7]
                f.write(str(num)+' '+str(y)+'\n')
                f.close()
            f=open(result,'a')
            f.write( 'bs\\rw\t 0/100\t 5/95\t 35/65\t 50/50\t 65/35\t 95/5\t 100/0')
            f.close()
            for bs,blocksize in [('512','0.5'),('4k','4'),('8k','8'),('16k','16'),('32k','32'),('64k','64'),('128k','128'),('1024k','1024')]:
                f=open(result,'a')
                f.write( '\n'+bs+'\t')
                f.close()
                f=open('iops/iops_all_data','a')
                f.write('\n'+blocksize+' ')
                f.close()
                for read in ['0','5','35','50','65','95','100']:
                    iops_gather = []
                    for num in range(rounds-4,rounds+1):
                        output = dire + '/' + str(num) + '_' + read + '_' + bs + '.log'
                        iops = base_p.fio_output_iops(output)
                        iops_gather.append(iops)
                    iopsavg = sum(iops_gather)/5
                    f=open(result,'a')
                    f.write(str(iopsavg)+'\t')
                    f.close()
                    f=open('iops/iops_all_data','a')
                    f.write(str(iopsavg)+' ')
                    f.close()
            break
    options = 'set terminal png \n set output '+'\'IOPS-sscp.png\''+' \n set title '+'\'IOPS Steady State Convergence Plot - All Block Size - 100% Writes\''+' \n set xlabel '+'\'Round\''+' \n set ylabel '+'\'IOPS\''+' \n set xrange [0:'+str(rounds+1)+'] \n set yrange [0:] \n plot '+'\'iops/iops_0_bs=4k\''+' using 1:2 title '+'\'bs=4k\''+' with linespoints lw 2,'+'\'iops/iops_0_bs=8k\''+' using 1:2 title '+'\'bs=8k\''+' with linespoints lw 2,'+'\'iops/iops_0_bs=16k\''+' using 1:2 title '+'\'bs=16k\''+' with linespoints lw 2,'+'\'iops/iops_0_bs=32k\''+' using 1:2 title '+'\'bs=32k\''+' with linespoints lw 2,'+'\'iops/iops_0_bs=64k\''+' using 1:2 title '+'\'bs=64k\''+' with linespoints lw 2,'+'\'iops/iops_0_bs=128k\''+' using 1:2 title '+'\'bs=128k\''+' with linespoints lw 2,'+'\'iops/iops_0_bs=1024k\''+' using 1:2 title '+'\'bs=1024k\''+' with linespoints lw 2'
    plot = 'echo \"\n' + options +'\n' +' \" | gnuplot'
    base_p.execute('iops-sscp ',plot) 
    options = 'set terminal png \n set output '+'\'IOPS-ssmw.png\''+' \n set title '+'\'IOPS Steady State Measurement Window - RND/4KiB\''+' \n set xlabel '+'\'Round\''+' \n set ylabel '+'\'IOPS\''+' \n set xrange ['+str(rounds-5)+':'+str(rounds+1)+'] \n set yrange ['+str(ss[3]*0.8)+':'+str(ss[3]*1.2)+'] \n plot '+'\'iops/iops_0_bs=4k_value\''+' using 1:2 title '+'\'IOPS\''+' with linespoints lw 2,'+'\'iops/iops_0_bs=4k_value\''+' using 1:(\$1+'+str(ss[3])+'-\$1)'+' title '+'\'Average\''+' with lines ,'+'\'iops/iops_0_bs=4k_slope\''+' using 1:2 title '+'\'Slope\''+' with lines, '+'\'iops/iops_0_bs=4k_value\''+' using 1:(\$1+'+str(ss[3]*0.9)+'-\$1)'+' title '+'\'90%*Average\''+' with lines lt 0 lw 2,'+'\'iops/iops_0_bs=4k_value\''+' using 1:(\$1+'+str(ss[3]*1.1)+'-\$1)'+' title '+'\'110%*Average\''+' with lines lt 0 lw 2'
    plot = 'echo \"\n' + options +'\n' +' \" | gnuplot'
    base_p.execute('iops-ssmw ',plot) 
    options = 'set terminal png \n set output '+'\'IOPS-ALL2D.png\''+' \n set title '+'\'IOPS - ALL RW Mix & BS - 2D Plot\''+' \n set xlabel '+'\'Block Size(KiB)\''+' \n set ylabel '+'\'IOPS\''+' \n set logscale x \n set logscale y \n plot '+'\'iops/iops_all_data\''+' using 1:2 title '+'\'0/100\''+' with linespoints lw 2,'+'\'iops/iops_all_data\''+' using 1:3 title '+'\'5/95\''+' with linespoints lw 2,'+'\'iops/iops_all_data\''+' using 1:4 title '+'\'35/65\''+' with linespoints lw 2,'+'\'iops/iops_all_data\''+' using 1:5 title '+'\'50/50\''+' with linespoints lw 2,'+'\'iops/iops_all_data\''+' using 1:6 title '+'\'65/35\''+' with linespoints lw 2,'+'\'iops/iops_all_data\''+' using 1:7 title '+'\'95/5\''+' with linespoints lw 2,'+'\'iops/iops_all_data\''+' using 1:8 title '+'\'100/0\''+' with linespoints lw 2'
    plot = 'echo \"\n' + options +'\n' +' \" | gnuplot'
    base_p.execute('iops-all2d ',plot) 
        
if __name__ == '__main__':
    os.system('mkdir '+ dire)
    system = base_p.get_system()
    #pblaze4 = base_p.get_pblaze4()
    with open(test_env,'a') as f:
        f.write(system+'\n')
    #f.write(pblaze4+'\n')
    test()
