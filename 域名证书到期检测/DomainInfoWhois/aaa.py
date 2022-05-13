#!/usr/bin/env python
# -*- coding:utf-8 -*-
# Yunsi Xiang
# 2021.5.17
# v1.0.1
# 通过curl获取状态响应时间,需要安装curl组件

import urllib3,json,logging,os

http = urllib3.PoolManager()
http_api = 'http://a69127cb9cb55752d.awsglobalaccelerator.com:32476/api/History/GetKline'
data = {'beginDate': 20210517,'beginTime':-1,'marketType':"8100",'peiod':1,'periodNum':4,'size':2,'symbol':'EURUSD'}
encoded_data = json.dumps(data).encode('utf-8')
# print('>>>>',encoded_data)

def http_request(method,http_api,data,logger1):

    # r = http.request('POST','http://a69127cb9cb55752d.awsglobalaccelerator.com:32476/api/History/GetKline',body=encoded_data,headers={'Content-Type': 'application/json','accept':'application/json'})
    r = http.request(method,http_api,body=data,headers={'Content-Type': 'application/json','accept':'application/json'})

    #输出响应的数据
    try:
        response_json = json.loads(r.data.decode('utf-8'))
        request_time = response_json['requestTime']
        logger1.info('时间:{}ms'.format(request_time))
    except Exception as e:
        # print('访问超时')
        logger1.info('访问异常')

if __name__ == '__main__':
    ab_path = os.path.abspath('./')
    res_log = os.path.join(ab_path, 'http_check.log')
    logging.basicConfig(level=logging.INFO,
                        format='%(asctime)s %(filename)s[line:%(lineno)d] %(levelname)s %(message)s',
                        datefmt='%Y-%m-%d %H:%M:%S',
                        filename=res_log,
                        filemode='a+')
    # formatter = logging.Formatter('%(name)-12s: %(levelname)-8s %(message)s')
    logger1 = logging.getLogger('myapp.area1')
    http_request('POST',http_api,encoded_data,logger1)