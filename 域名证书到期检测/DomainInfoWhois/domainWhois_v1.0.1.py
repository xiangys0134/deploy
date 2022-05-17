#!/user/bin/env python3
# -*- coding: utf-8 -*-
# yousong.xiang
# 2022.5.13
# v1.0.1

# 功能: 查看证书到期时间，执行速度受ssl请求响应及域名数量影响，可考虑多线程检测
# pip3 install requests
# yum install whois

import whois,os,csv,json,requests
from datetime import datetime

csv_dir = '/data/domain/csv/whois_domain'
now = datetime.now().strftime("%Y.%m.%d.%H.%M")
headers = ['域名','域名到期时间','域名剩余天数','所属运营商']
csv_r_name = 'domain.csv'
csv_w_name = 'whois%s.csv'%now

http_api = 'http://192.168.7.118:8008/whoisgetlist'
url = 'https://oapi.dingtalk.com/robot/send?access_token=7d808b5b47cd887e83cd98d9b7d93bcde5b778ba6a35755d4afce972d34601ed'
# url = 'https://oapi.dingtalk.com/robot/send?access_token=7d808b5b47cd887e83cd98d9b7d93bcde5b778ba6a35755d4afce972d34601ed'
csvurl = 'http://192.168.7.57:808/whois_domain'

if not os.path.exists(csv_dir): os.makedirs(csv_dir)

def getData(text_content):
    '''返回钉钉发送消息格式'''
    text = {
        'msgtype': 'markdown',
        'markdown':{
            'title': '域名到期检测',
            'text': text_content
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

def domainCheck(hostname,operator):
    '''域名到期时间检查'''
    try:
        domain = whois.query(hostname)
        now = datetime.now()
        expir_time = domain.__dict__['expiration_date']
        end_days = (expir_time - now).days

        itemDic = {'域名': hostname, '域名到期时间': expir_time.strftime('%Y-%m-%d'), '域名剩余天数': end_days,'所属运营商':operator}
        #print(domain.__dict__)
        print(itemDic)
        return itemDic
    except Exception as e:
        print('errorrr',e)
        itemDic = {'域名': hostname, '域名到期时间': 'whois检查失败，请手工检查!', '域名剩余天数': '检查失败!','所属运营商':operator}
        return itemDic

with open(os.path.join(csv_dir,'%s'%csv_w_name),'w',encoding='utf-8',newline='') as f1:
    r = requests.get(http_api)

    if r.status_code !=200:
        print('api访问失败')
        os._exit(4)

    csv_writer = csv.DictWriter(f1,fieldnames=headers)
    csv_writer.writeheader()

    result = json.loads(r.text)
    for k,v in result.items():
        name = result[k]['name']
        ret = domainCheck(k,name)
        csv_writer.writerow(ret)

    msg = "## 域名到期检测\n - message：如有解析不出来请手动登陆控制台查看到期时间!\n - [链接地址](%s/%s)"%(csvurl,csv_w_name)
    data = getData(msg)
    sendDing(url, data)

    print('检查完毕，csv表格路径：%s'%os.path.join(csv_dir,csv_w_name))