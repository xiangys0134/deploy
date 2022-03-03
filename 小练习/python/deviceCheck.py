#!/usr/bin/env python3
# -*- coding:utf-8 -*-
# yousong.xiang
# 2022.3.3
# v1.0.1
# 功能: 查看Linux分区可用空间

import psutil,logging,os

def getDeviceName():
    disk_list = []
    res = psutil.disk_partitions()
    for device in res:
        disk_list.append(device.mountpoint)
    return disk_list

def usePercent(*args,logger=None):
    '''打印分区使用率'''
    for i in args:
        res = psutil.disk_usage(i)
        if logger:
            logger.info('分区%s可用率：%s'%(i,res.percent))
        else:
            print('分区%s可用率：%s'%(i,res.percent))



if __name__ == '__main__':
    check_log = os.path.join('/tmp', 'deviceCheck.log')
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', filename=check_log,
        datefmt='%Y-%m-%d %H:%M:%S'
    )

    device_log = logging.getLogger('diskcheck')
    device_path = getDeviceName()
    usePercent(*device_path,logger=device_log)
