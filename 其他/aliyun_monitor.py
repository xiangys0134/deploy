#!/usr/local/py27/bin/python

import os
import re
import time
import json
import urllib2
from aliyunsdkcore import client
from aliyunsdkcms.request.v20170301 import PutCustomMetricRequest

clt = client.AcsClient('212232','3423423')





def put_metric(name, value):
    data = [{'groupId': 101,'metricName': 'apache','dimensions': 
            {'name': name},'type': 0,'values': {'value': value}}]
    request = PutCustomMetricRequest.PutCustomMetricRequest()
    request.set_MetricList(json.dumps(data))
    result = clt.do_action_with_exception(request)
    return result


def apache_status():
    '''
        items is   [(itemname, itemsvalue(str to int is ok)]
    '''
    respone = urllib2.urlopen('http://localhost/wy-server-status?auto')
    body = respone.read()
    items = re.findall('([a-zA-z\ ]+Workers): (\d+)', body)
    items1 = [("httpd.processNum", os.popen('ps -ef | grep httpd | grep -v grep | wc -l').read().strip())]
    #items1 = re.findall('([a-zA-z\ ]+Accesses): (\d+)', body)
    #items = re.findall('([a-zA-z\ ]+): (\d+)', body)
    #need_items = 'Workers'
    for i in items + items1:
        #if need_items in i[0]:
        print time.strftime("%Y/%m/%d %H:%M:%S"), "Put", i[0], i[1], put_metric(i[0], int(i[1]))


if __name__ == '__main__':
    apache_status()
