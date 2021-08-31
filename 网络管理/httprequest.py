#!/user/bin/env python3
# -*- coding: utf-8 -*-
# yousong.xiang
# 2020.8.31
# v1.0.1
# 检测url是否正常

import subprocess
import threading
import os
import logging
import json
import requests
import sys

check_alive_list = []
check_unreacheable_list = []
log_dir = '/tmp'
file_log = 'check_http_api.log'
file_info = 'domainInfo'

def gaojing(data):
    # 将消息提交给钉钉机器人
    headers = {'Content-Type': 'application/json;charset=utf-8'}
    # 注意替换钉钉群的机器人webhook
    webhook = "https://oapi.dingtalk.com/robot/send?access_token=90fea408c219b11aa93ae518ad38460074077737992144dcfb86b65f08093b961"
    requests.post(url=webhook,data=json.dumps(data),headers=headers)

def get_data(text_content):
    # 返回钉钉机器人所需的文本格式
    text = {
        "msgtype": "text",
        "text": {
            "content": text_content
        },
    }
    # print(json.dumps(text))
    return text

def http_list_get(file_info):
    """读取监控信息文件,这里不做兼容处理，信息文件必须由值且按照规范格式"""
    current_filename = os.path.dirname(sys.argv[0])

    with open(os.path.join(current_filename,file_info),'r',encoding='utf-8') as f1:
        http_list = eval(f1.read())

    return http_list

def check_api(http_list,logger1,logger2):
  """ curl请求 """
  try:
    while http_list:
      http_json = http_list.pop()
      if http_json["uri"] == "/":
        http_url = '{}://{}'.format(http_json["scheme"],http_json["ip"])
      else:
        http_url = '{}://{}/{}'.format(http_json["scheme"], http_json["ip"],http_json["uri"])
      result_code = subprocess.call('/bin/curl --connect-timeout 10 -k -v -I {} -H "Host:{}"'.format(http_url,http_json["domain"]), shell=True)
      if result_code:
        check_unreacheable_list.append(http_json)
        logger2.error('{} ip:{}异常'.format(http_url,http_json["ip"]))
      else:
        check_alive_list.append(http_json)
        logger1.info('{} ip:{}正常'.format(http_url, http_json["ip"]))
  except Exception as f:
    pass

def main():
  res_log = os.path.join(log_dir, file_log)
  logging.basicConfig(level=logging.INFO,
                      format='%(asctime)s %(filename)s[line:%(lineno)d] %(levelname)s %(message)s',
                      datefmt='%Y-%m-%d %H:%M:%S',
                      filename=res_log,
                      filemode='a+')
  logger1 = logging.getLogger('myapp.area1')
  logger2 = logging.getLogger('myapp.area2')

  threads = []
  http_list = http_list_get(file_info)
  for i in range(1, 10):
    thr = threading.Thread(target=check_api, args=(http_list,logger1, logger2))
    thr.start()
    threads.append(thr)
  for thr in threads:
    thr.join()

  while check_unreacheable_list:
    http_info = check_unreacheable_list.pop()
    if http_info["uri"] == "/":
      http_url = '{}://{}'.format(http_info["scheme"], http_info["domain"])
    else:
      http_url = '{}://{}/{}'.format(http_info["scheme"], http_info["domain"], http_info["uri"])
    text_content = 'alert>{} ip:{}异常 站点黑盒探测'.format(http_url,http_info["ip"])
    data = get_data(text_content)
    gaojing(data)
    exit(4)

if __name__ == '__main__':
  main()
