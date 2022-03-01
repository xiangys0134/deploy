#!/usr/bin/env python3
# -*- coding:utf-8 -*-
# yousong.xiang
# 2022.3.1
# v1.0.1
# 功能: 查看Linux分区可用空间

import os,re

def diskCheck(device):
    data_info = os.statvfs(device)
    ret = data_info.f_bsize * data_info.f_bavail /1024/1024
    return '%sM'%ret


def diskName():
    ret = os.popen('df -h|grep -v -i tmpfs|grep -v -i Filesystem|grep -v -i boot|grep -v -i swap')
    disk_list = re.split('\n',ret.read().strip())

    device_list = []
    for diskname in disk_list:
        res = re.split('\s+', diskname)
        device_list.append(res[-1])

    for i in device_list:
        res = diskCheck(i)
        print('%s 目录可用空间为%s'%(i,res))

if __name__ == '__main__':
    diskName()




