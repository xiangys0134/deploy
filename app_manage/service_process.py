#!/usr/bin/env python
# -*- coding:utf-8 -*-
# yousong.xiang
# 2022.2.24
# v1.0.1
# 功能: Linux进程检测管理，Linux系统运行

from datetime import datetime

import re,os,subprocess


check_log='/tmp/serviceProcess.log'
now = datetime.now()
time_now = now.strftime('%Y-%m-%d %H:%M:%S')



def serviceCheck(srv):
    resstr = os.popen('systemctl status '+ srv).read()
    shell_str = 'echo %s %s服务状态检测异常!  >> %s' % (time_now, srv, check_log)
    res = re.search('running',resstr)
    if not res:
        os.system(shell_str)
        forloops = 2
        while forloops > 0:
            os.system('systemctl stop '+ srv)
            result = os.system('systemctl start '+ srv)
            if result == 0:
                break
            forloops -= 1

def processCheck(arg1,arg2):
    pid_num_str='ps -ef|grep %s|grep -v grep|wc -l'%(arg1)
    shell_str = 'echo %s %s进程状态检测异常!  >> %s' % (time_now, arg1, check_log)
    res = os.popen(pid_num_str).read()
    res = res.split('\n')[0]
    # print(res)
    if res == '0':
        os.system(shell_str)
        forloops = 2
        while forloops > 0:
            result = os.system('source /etc/profile;' + arg2)
            print('result',result)
            if result == 0:
                break
            forloops -= 1

if __name__ == '__main__':
    # Example1
    serviceCheck('nginx.service')

    # Example2
    # processCheck('usr/sbin/nginx','/usr/sbin/nginx')