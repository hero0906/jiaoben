import subprocess 
import uuid
import os
import traceback
from pathlib import Path

def exc(command):

    ret = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True, timeout=60)

    return ret.returncode
#        print("|%-50s |SUCCESS|" % command)
#    else:
#        print("\033[1;33;44m|%-50s |ERROR\033[0m" % command)


PATH = 'cy_test001'
IP = '192.168.45.11'
ID = str(uuid.uuid4())

#get node information, type(mds, oss)
node_info = ('yrcli --node --type=oss',
       'yrcli --node --type=mds',
       'yrcli --node --type=client',
       'yrcli --node --type=mgmt')

#get mds and oss informations
osd_info = ( 'yrcli --osd --type=mds',
       'yrcli --osd --type=oss',)

#mode control of client access
acl_set = ('yrcli --acl --op=add --path=/{path} --ip={ip} --mode=rw'.format(path=PATH, ip=IP),
        'yrcli --acl --op=add --path=/{path} --id={Id} --mode=rw'.format(path=PATH, Id=ID),
        'yrcli --acl --op=list',
        'yrcli --acl --op=del --path=/{path} --ip={ip}'.format(path=PATH, ip=IP),
        'yrcli --acl --op=del --path=/{path} --id={Id}'.format(path=PATH, Id=ID),
        )

#mode control of yrcli access
cliacl_set = ('yrcli --cliacl --op=add --ip={ip}'.format(ip=IP),
              'yrcli --cliacl --op=list',
              'yrcli --cliacl --op=del --ip={ip}'.format(ip=IP),
       )

#get group information
group_info = ('yrcli --group --type=mds',
              'yrcli --group --type=oss',)

#create mirror groups snapshot
create_snap = ('yrcli --createsnapshot',
               'yrcli --osdbalance --type=oss')

#display node version, type(mds|oss|client|mgmt))
get_version = ('yrcli --version --type=mds',
               'yrcli --version --type=oss',
               'yrcli --version --type=client',
               'yrcli --version --type=mgmt')

#config extend entry configuration
entry = ('yrcli --setentry --stripesize=1m --schema=mirror --stripecount=8 /{path} -u'.format(path=PATH),
        'yrcli --reloadentry /{path} -u'.format(path=PATH),
        'yrcli --getentry /{path} -u'.format(path=PATH),)

#create a new file
file_option = ('yrcli --mkdir --owners=1 /{path}/{path} -u'.format(path=PATH),
               'yrcli --create --stripesize=1m --stripecount=4 --vol=default /{path}/{files} -u'.format(path=PATH,
                   files=ID ),
               'yrcli --rename --from=/{path}/{path} --to=/{path}/{path}{path} -u'.format(path=PATH),
               'yrcli --listdir /{path} -u'.format(path=PATH),
               'yrcli --rmdir /{path}/{path}{path} -u'.format(path=PATH),
               'rm -fr /mnt/yrfs/{path}/{files}'.format(path=PATH, files=ID)
               )

monitor = ('yrcli --nodestat --type=oss',
           'yrcli --nodestat --type=mds',
           'yrcli --getsla',
           'yrcli --sysinfo')

limit = ('yrcli --setprojectquota --path=/{path} --unmounted --spacelimit=1G --inodelimit=1000'.format(path=PATH),
         'yrcli --setprojectquota --path=/{path} --unmounted --spacelimit=2000G --inodelimit=900000 --update'.format(path=PATH),
         'yrcli --rmprojectquota --path=/{path} --unmounted'.format(path=PATH),
         'yrcli --getprojectquota',

         'yrcli --setqos --path=/{path} --unmounted --rbps=1G --wbps=1G --riops=1000 --wiops=1000\
         --mops=100'.format(path=PATH),
         'yrcli --setqos --path=/{path} --unmounted --tbps=1G --tiops=2K --mops=1K'.format(path=PATH),
         'yrcli --getqos',
         'yrcli --rmqos --path=/{path} --unmounted'.format(path=PATH),
         )

debug = ('yrcli --fsck /data/mds0 --thread=4 --cfg=/etc/yrfs/mds0.d/yrfs-meta.conf',)

commands = node_info + osd_info + acl_set + cliacl_set + group_info + create_snap + get_version +\
        entry + limit + file_option + monitor + debug

mount_status = exc("findmnt /mnt/yrfs")
yrfs_acl = exc("yrcli --acl --op=list")
if yrfs_acl != 0:
    print("this node haven't acl permission")
    exit()

if mount_status == 0:
    print("print test running!!!")
    try:
         test_dir = Path("/mnt/yrfs/" + PATH) 
         if test_dir.is_dir():
             os.removedirs("/mnt/yrfs/" + PATH)
         else:
             os.mkdir("/mnt/yrfs/" + PATH)
         for command in commands:
             status = exc(command)
             if status == 0:
                 print("|%-50s |SUCCESS|" % command) 
             else:
                 print("\033[1;33;35m|%-50s |ERROR\033[0m" % command)	
         os.rmdir("/mnt/yrfs/" + PATH)
    except Exception as e:
         traceback.print_exc()
else:
    print("mount point no exsit!!!")
