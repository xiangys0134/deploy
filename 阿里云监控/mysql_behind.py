#!/usr/bin/env python 
# -*- coding:utf-8 -*-

import os,sys
import re
import time
import json
import urllib2
from aliyunsdkcore import client
from aliyunsdkcms.request.v20170301 import PutCustomMetricRequest

clt = client.AcsClient('LTAIGViH9EgPnWFC','03b8ahaBldvRpc5M7NMs1Ro8tIUHh6')
user = 'root'
password = '67qm3ddkoVSElks56'


def put_metric(name, value):
    data = [{'groupId': 23516,'metricName': 'mysql_behind','dimensions':
            {'name': name},'type': 0,'values': {'value': value}}]
    request = PutCustomMetricRequest.PutCustomMetricRequest()
    request.set_MetricList(json.dumps(data))
    result = clt.do_action_with_exception(request)
    return result

#获取延迟信息函数
def mysql_behid():
    values = os.popen('mysql -u%s -p%s -e "show slave status\\G"|egrep -v "grep"|grep -w "Seconds_Behind_Master"'%(user,password))
    values = values.readlines()
    values = str(values[0]).strip().split(':')[1]
    result = put_metric('mysql_behid',int(values))

mysql_behid()
