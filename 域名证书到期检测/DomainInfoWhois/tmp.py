#!/user/bin/env python3
# -*- coding: utf-8 -*-
# yousong.xiang
# 2022.5.13
# v1.0.1

# 功能: 查看证书到期时间，执行速度受ssl请求响应及域名数量影响，可考虑多线程检测
# pip3 install requests
# yum install whois

import whois,os,csv,json,requests,urllib3
from datetime import datetime

NOW_TIME = datetime.now().strftime("%Y.%m.%d.%H.%M")
HEADERS = ['域名','域名到期时间','域名剩余天数']
CSVURL = 'http://192.168.7.57:808/ssl_domain'
DINGDING_API = 'https://oapi.dingtalk.com/robot/send?access_token=62dadf25b1422a93887199537e8e5386350de88f78f8a45daa707841fb37de49'

http_api = 'http://192.168.7.118:8008/domainslist'
csv_w_name = 'domainwhois%s.csv'%NOW_TIME
http = urllib3.PoolManager()
csv_dir = '/opt/whois_domain'
