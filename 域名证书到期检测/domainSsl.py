#!/user/bin/env python3
# -*- coding: utf-8 -*-
# yousong.xiang
# 2022.3.19
# v1.0.1
# 功能: 查看证书到期时间，执行速度受ssl请求响应及域名数量影响，可考虑多线程检测
# pip3 install pyopenssl python-dateutil

import csv,os,OpenSSL,sslsocket,json,requests
from datetime import datetime
from dateutil import parser

#csv_source_dir = r'C:\Users\xiangys0134\Desktop\csv操作\csv'
csv_source_dir = '/data/domain/csv/source_dir'
#csv_dir = r'C:\Users\xiangys0134\Desktop\csv操作'
csv_dir = '/data/domain/csv/ssl_domain'
now = datetime.now().strftime("%Y%m%d%H%M%S")
headers = ['域名','证书到期时间','证书剩余天数']
csv_r_name = 'ssl.csv'
csv_w_name = 'domainssl%s.csv'%now

if not os.path.exists(os.path.join(csv_source_dir,csv_r_name)): exit(5)
if not os.path.exists(csv_dir): os.makedirs(csv_dir)

url = 'https://oapi.dingtalk.com/robot/send?access_token=62dadf25b1422a93887699537e8e5386350de88f78f8a15daa707841fb37de49'
csvurl = 'http://192.168.7.57:808/ssl_domain'

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


with open(os.path.join(csv_source_dir,csv_r_name),'r',encoding='utf-8') as f, \
     open(os.path.join(csv_dir,'%s'%csv_w_name),'w',encoding='utf-8',newline='') as f1:
    csv_reader = csv.reader(f)
    csv_writer = csv.DictWriter(f1,fieldnames=headers)
    csv_writer.writeheader()

    # # 构造字典
    # itemDic = {'域名': 'blog.g6p.cn', '证书到期时间': '2022-06-19', '证书剩余天数': 90}
    for line in csv_reader:
        if len(line) == 0: continue
        if line[0] == '域名': continue
        if line[0] == '': continue
        if '#' in line[0]: continue
        print(line)
        if len(line) == 2:
            ret = certCheck(*line)
        else:
            ret = False
        if ret:
            csv_writer.writerow(ret)
    msg = '''
    Alert DingDing INFO
    域名证书到期检查链接：%s
    文件名：%s
    '''%(csvurl,csv_w_name)

    data = getData(msg)
    sendDing(url, data)
    print('检查完毕，csv表格路径：%s'%os.path.join(csv_dir,csv_w_name))
