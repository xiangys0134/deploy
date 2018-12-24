#!/usr/bin/python
# -*- coding: utf-8 -*-
from urllib import parse,request
# import win32serviceutil
# import win32service
# import win32event
import os
import re
import time
import sys



# class PythonService(win32serviceutil.ServiceFramework):
class PythonService():
    # _svc_name_ = "PythonService"
    # _svc_display_name_ = "Python Service Test"
    # _svc_description_ = "This is a python service test code "

    def __init__(self):
        # win32serviceutil.ServiceFramework.__init__(self, args)
        # super().__init__()
        # self.hWaitStop = win32event.CreateEvent(None, 0, 0, None)
        # self.logger = self._getLogger()
        self.run = True
        self.citrix_http = 'http://192.168.0.63'
        self.citrix_log = 'citrix_monitor.log'
        self.citrix_file_dir = r'C:\bat_logs'


    def citrix(self):
        """
        1.获取远程窗口在运行的用户
        2.如果未获取关键字"运行中"的用户则return 0
        """
        cmd = os.popen("query user")
        l1 = []
        l2 = []
        for i in cmd:
            if '运行中' in i:
                # print(i)
                i = i.replace('\n', '')
                str1 = re.sub('\s+', ',', i)
                if '>' in str1:
                    str1 = str1.replace('>', '')
                l1.append(str1.strip(','))

        if not l1: return 0

        print(l1)

        for i in l1:
            str2 = i.split(',')
            # print(str2[0],str2[1])
            print(str2[0])
            if len(l1) == 1 and str2[1].startswith('rdp'):
                # print('bbb')
                return 0
            if not str2[1].startswith('rdp'):
                l2.append(str2[0])

        print(l2)
        if not l2: return 0

        if len(l2) == 1:
            return l2[0]
        else:
            str3 = ','.join(l2)
            return str3

    def SvcDoRun(self):
        while True:
            try:
                header_dict = {
                    "User-Agent": 'Mozilla/4.0 (compatible; MSIE 5.5; Windows NT)'
                }
                #url = citrix()
                url = self.citrix()
                #file_log = r'C:\bat_logs'
                time_date = date_time = time.time()
                #if not os.path.exists(file_log):
                if not os.path.exists(self.citrix_file_dir):
                    # print('aaaa')
                    os.system(os.makedirs(self.citrix_file_dir))
                # url = 'admin'
                if url == 0 or url == 'None':
                    print('无远程用户登录')
                    with open(os.path.join(self.citrix_file_dir, self.citrix_log), 'a+', encoding='utf8') as f:
                        f.seek(2)
                        f.write('\n%s 无远程用户登录' % time.strftime('%Y-%m-%d %X', time.localtime(time_date)))
                    exit()
                http_url = '%s/pub-uds/monitor/virtual_desk?username=%s' % (self.citrix_http,url)

                print(url, http_url)
                ret = request.Request(url=http_url, headers=header_dict)
                res = request.urlopen(ret, timeout=2)
                result = res.read().decode('utf8')
                with open(os.path.join(self.citrix_file_dir, self.citrix_log), 'a+', encoding='utf8') as f1:
                    f1.seek(2)
                    f1.write('\n%s %s  %s' % (
                    time.strftime('%Y-%m-%d %X', time.localtime(time_date)), str(result), http_url))
                print(result)
            except Exception as e:
                with open(os.path.join(self.citrix_file_dir, self.citrix_log), 'a+', encoding='utf8') as f2:
                    f2.seek(2)
                    f2.write('\n%s %s' % (time.strftime('%Y-%m-%d %X', time.localtime(time_date)), e))
                print(e)
            time.sleep(3)



c1 = PythonService()
c1.SvcDoRun()


