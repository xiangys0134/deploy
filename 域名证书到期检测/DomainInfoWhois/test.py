#!/user/bin/env python3
# -*- coding: utf-8 -*-
# yousong.xiang
# 2022.5.13
# v1.0.1

# 功能: 查看证书到期时间，执行速度受ssl请求响应及域名数量影响，可考虑多线程检测
# pip3 install pyopenssl python-dateutil

import csv,os,OpenSSL,sslsocket,json,requests
from datetime import datetime
from dateutil import parser

NOW_TIME = datetime.now().strftime("%Y.%m.%d.%H.%M")
HEADERS = ['域名','证书到期时间','证书剩余天数']
CSVURL = 'http://192.168.7.57:808/ssl_domain'
DINGDING_API = 'https://oapi.dingtalk.com/robot/send?access_token=62dadf25b1422a93887199537e8e5386350de88f78f8a45daa707841fb37de49'

http_api = 'http://192.168.7.118:8008/domainslist'
csv_w_name = 'domainwhois%s.csv'%NOW_TIME

csv_dir = '/data/domain/csv/ssl_domain'

if not os.path.exists(csv_dir): os.makedirs(csv_dir)

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

def certCheck(hostname,port=443):
    "域名证书有效性检查"
    try:
        cert= sslsocket.get_server_certificate((hostname, port)).encode("utf-8")
        cert_obj = OpenSSL.crypto.load_certificate(OpenSSL.crypto.FILETYPE_PEM, cert)
        datetime_struct = parser.parse(cert_obj.get_notAfter().decode("utf-8"))
        #datetime_struct = parser.parse(cert_obj.get_notAfter().decode())
        ssl_date = datetime_struct.strftime('%Y-%m-%d')
        # print(ssl_date)

        ssl_strptime = datetime.strptime(ssl_date,'%Y-%m-%d')
        ssl_now = datetime.now()
        end_days = (ssl_strptime - ssl_now).days

        itemDic = {'域名': hostname, '证书到期时间': ssl_date, '证书剩余天数': end_days}
        # print(itemDic)
        return itemDic
    except Exception as e:
        # print("错误：",e)
        itemDic = {'域名': hostname, '证书到期时间': '检查失败，确认站点是否部署', '证书剩余天数': '检查失败!'}
        # print(itemDic)
        return itemDic

with open(os.path.join(csv_dir,'%s'%csv_w_name),'w',encoding='utf-8',newline='') as f1:
    r = requests.get(http_api)

    if r.status_code != 200:
        print('api访问失败')
        os._exit(4)

    csv_writer = csv.DictWriter(f1, fieldnames=HEADERS)
    csv_writer.writeheader()

    result = json.loads(r.text)
    for domain_dict in result["data"]:
        name = domain_dict['name']
        port = domain_dict['port']
        ret = certCheck(name,port=port)
        csv_writer.writerow(ret)

msg = '''
Alert DingDing INFO
域名Whois检查链接：%s 注意：有些注册商屏蔽了whois，需要手工查看
文件名：%s
'''%(CSVURL,csv_w_name)

data = getData(msg)
sendDing(DINGDING_API, data)

print('检查完毕，csv表格路径：%s'%os.path.join(csv_dir,csv_w_name))