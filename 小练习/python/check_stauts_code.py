#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os,re

class CheckStusCode(object):
    def __init__(self,filename):
        self.filename = filename

    def fileExists(self):
        if os.path.exists(self.filename):
            return '%s'%(self.filename)

    def secreteFile(self):
        if os.path.exists(self.filename):
            base_name = os.path.basename(self.filename)
            dir_name = os.path.dirname(self.filename)
            secretename = os.path.join(dir_name,'.%s'%(base_name))
            return secretename

    def tellFile(self):
        if os.path.exists(self.filename):
            base_name = os.path.basename(self.filename)
            dir_name = os.path.dirname(self.filename)
            secretename = os.path.join(dir_name,'.tell%s'%(base_name))
            return secretename

    def checkFile(self):
        if not self.fileExists():
            print('文件不存在!')
            exit()
        with open(self.filename, encoding='utf-8') as fp1, \
        open(self.secreteFile(),mode='a',encoding='utf-8') as fp2, \
        open(self.tellFile(),mode='w',encoding='utf-8') as ftell:
            if os.path.getsize(self.tellFile()):
                tell_res = ftell.read()
            else:
                tell_res = 1

            fp1.seek(tell_res)
            res = fp1.read()
            if not res:
                fp1.seek(1)
                res = fp1.read()
            restell = fp1.tell()
            for line in res.split('\n'):
                re_str = re.compile(r' 50\d ')
                res_code = re_str.findall(line)
                if res_code:
                    fp2.write(line)
            ftell.write(str(restell))


file = CheckStusCode('/data/wwwlogs/httplocalhost-access.log')
file.checkFile()


