#!/usr/bin/env python
# -*- coding: utf-8 -*-
#监控redis状态

import os
import re
import time
import json
import urllib2
from aliyunsdkcore import client
from aliyunsdkcms.request.v20180308 import PutCustomMetricRequest

password = "7UdUys8FM3nmrhvQ2YOLpTNwYSzShkPsE76"
port = 6379
cli = "/usr/bin/redis-cli"
options = "ping"
clt = client.AcsClient('LTAIZT4JJEH44hM9','MtUor3Cpvj1ex5COf5HYx41sFHdHOG')

def put_metric(name, value):
    data = [{'groupId': 102264,'metricName': 'redis','dimensions':
            {'name': name},'type': 0,'values': {'value': value}}]
    request = PutCustomMetricRequest.PutCustomMetricRequest()
    request.set_MetricList(json.dumps(data))
    result = clt.do_action_with_exception(request)
    return result


try:

    value = os.popen('%s -a %s %s 2>/dev/null' %(cli, password, options))
    value =  value.readlines()[0].strip('\n')
    if value == "PONG":
        value = 1
except BaseException as e:
    value = 0


#print value
put_metric('redis_monitor_pro',value)
