#!/usr/bin/env python3
# -*- coding:utf-8 -*-
# yousong.xiang
# 2022.3.2
# v1.0.1
# 功能: 查看系统cpu资源并且告警

import json,requests,psutil
from datetime import datetime

url = 'https://oapi.dingtalk.com/robot/send?access_token=0a2a20bebf254aa7871a3e0e54eeef635208e607e62419122341dd58dc5cd526'

def getData(text_content):
    '''返回钉钉发送消息格式'''
    text = {
        'msgtype': 'text',
        'text': {
            'content': text_content
        },
    }
    return text

def sendDing(url,data):
    '''钉钉发送'''
    headers = {'Content-Type':'application/json;charset=utf-8'}
    res = requests.post(url=url,data=json.dumps(data),headers=headers)
    if res.status_code != 200:
        now = datetime.now()
        time_str = now.strftime('%Y-%m-%d %H:%M:%S')
        print('%s 发送消息失败!'%time_str)
        return 2
    return 1

def main(percent=90):
    res_percent = psutil.cpu_percent(interval=2)
    res_loadavg = psutil.getloadavg()
    res_cpucount = psutil.cpu_count()

    if res_percent >= percent and res_loadavg[0] >= res_cpucount:
        msg = 'alert报警：cpu使用率%s%%,负载%s'%(res_percent,res_loadavg[0])
        data = getData(msg)
        sendDing(url, data)



if __name__ == '__main__':
    main(percent=85)
