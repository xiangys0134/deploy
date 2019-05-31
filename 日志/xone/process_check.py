#!/bin/env python2
# -*- coding: utf-8 -*-
# xone端口检查
# Author yousong.xiang 250919938@qq.com
# Date 2019.5.9
# v1.0.1

import time,os

SERVER_DIC={
    "regitry-server":8761,
    "monitor-service":8765,
    "config-server":8763,
    "gateway":8762,
    "tm-service":7970,
    "file-service":8768,
    "oauth-service":8766,
    "user-service":8764,
    "bond-service":8767
    }

def ProcessCheck(dic):
    if isinstance(dic,dict) == 0:
        print "参数必须为字典格式"
        return 8
    with open('/tmp/process_status.log','a') as f:
        for k,v in dic.items():
            ticks = time.strftime("%a %b %d %H:%M:%S %Y", time.localtime())
            status_count = os.popen('netstat -aon|grep -w %s |wc -l'%v)
            status_count = status_count.read()
            #f.write('%s %s %s %s #####'%(ticks,k,v,status_count))
            #f.write('\n')
            if int(status_count) == 0:
                f.write('%s %s,port:%s stoping'%(ticks,k,v))
                f.write('\n')
                #print k,v
            else:
                #print k,v
                pass
            #time.sleep(3)   
ProcessCheck(SERVER_DIC)


