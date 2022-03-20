#!/user/bin/env python3
# -*- coding: utf-8 -*-
# yousong.xiang
# 2022.3.19
# v1.0.1
# 功能: 查看证书到期时间，执行速度受ssl请求响应及域名数量影响，可考虑多线程检测
# pip3 install requests
# yum install whois

import whois,os,csv,json,requests
from datetime import datetime

#csv_source_dir = r'C:\Users\xiangys0134\Desktop\csv操作\csv'
csv_source_dir = '/data/domain/csv/source_dir'
#csv_dir = r'C:\Users\xiangys0134\Desktop\csv操作'
csv_dir = '/data/domain/csv/whois_domain'
now = datetime.now().strftime("%Y%m%d%H%M%S")
headers = ['域名','域名到期时间','域名剩余天数']
csv_r_name = 'domain.csv'
csv_w_name = 'domainwhois%s.csv'%now

url = 'https://oapi.dingtalk.com/robot/send?access_token=62dadf25b1422a93887199537e8e5386350de88f78f8a45daa707841fb37de49'
csvurl = 'http://192.168.7.57:808/ssl_domain'

if not os.path.exists(os.path.join(csv_source_dir,csv_r_name)): exit(5)
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

def domainCheck(hostname):
    '''域名到期时间检查'''
    try:
        domain = whois.query(hostname)
        now = datetime.now()
        expir_time = domain.__dict__['expiration_date']
        end_days = (expir_time - now).days

        itemDic = {'域名': hostname, '域名到期时间': expir_time.strftime('%Y-%m-%d'), '域名剩余天数': end_days}
        #print(domain.__dict__)
        print(itemDic)
        return itemDic
    except Exception as e:
        print('errorrr',e)
        itemDic = {'域名': hostname, '域名到期时间': 'whois检查失败，请手工检查!', '域名剩余天数': '检查失败!'}
        return itemDic

with open(os.path.join(csv_source_dir,csv_r_name),'r',encoding='utf-8') as f, \
     open(os.path.join(csv_dir,'%s'%csv_w_name),'w',encoding='utf-8',newline='') as f1:
    csv_reader = csv.reader(f)
    csv_writer = csv.DictWriter(f1,fieldnames=headers)
    csv_writer.writeheader()

    # # 构造字典
    # itemDic = {'域名': 'blog.g6p.cn', '证书到期时间': '2022-06-19', '证书剩余天数': 90}
    for line in csv_reader:
        print('line',line)
        if len(line) == 0: continue
        if line[0] == '域名': continue
        if line[0] == '': continue
        if '#' in line[0]: continue
        # print(line)
        if len(line) == 1:
            ret = domainCheck(*line)
        else:
            ret = False
        if ret:
            csv_writer.writerow(ret)
    msg = '''
    Alert DingDing INFO
    域名Whois检查链接：%s 注意：有些注册商屏蔽了whois，需要手工查看
    文件名：%s
    '''%(csvurl,csv_w_name)

    data = getData(msg)
    sendDing(url, data)

    print('检查完毕，csv表格路径：%s'%os.path.join(csv_dir,csv_w_name))
