#!/usr/bin/env python
# coding: utf-8
""" 监控系统 系统负载与io等待 网络连接线 连续三次超过阀值则报警
Author: chenyanghong
Date : 2018-03-27
E-mail: 32415397@qq.com
"""
import commands
import requests
import time
import sys
import copy
import re

reload(sys)
sys.setdefaultencoding('utf-8')


def send_monitor(send_str):  # 发送报警信息
    global f
    date_str = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
    warn_url = "https://oapi.dingtalk.com/robot/send?access_token=7be23f0cee4d7d77678c0e68aa9fcc79e1a1a09dd125f0944a2f370f69ffe7d4"
    data = '{"msgtype": "text",  "text": { "content": "%s %s" } }' % (date_str, send_str)
    headers = {"Content-Type": "application/json",
               'User-Agent': 'Mozilla/5.0 (X11; U; Linux x86_64; en-US) AppleWebKit/532.0 (KHTML, like Gecko) Chrome/4.0.202.0 Safari/532.0'}
    r = requests.post(warn_url, data=data, headers=headers, timeout=5)
    result_text = r.text
    if re.search(r'ok', str(result_text)):
        log_line = "%s 发送报警内容:%s 成功" % (date_str, send_str)
        f.write("%s\n" % log_line)
        f.flush()
    else:
        log_line = "%s 发送报警内容:%s 失败" % (date_str, send_str)
        f.write("%s\n" % log_line)
        f.flush()


def action_check(resource_stat_key, warn_dict_key, resource_stat, action_stat, host):
    """ 检测发送报警 通用方法
    :param resource_stat_key: 资源状态字典key
    :param warn_dict_key:  阀值字典key
    :param host:  主机名
    :param action_stat:  每个主机的报警状态
    :param resource_stat:  每个主机的资源状态
    :return:
    """
    global warn_dict, resource_message
    # print "host:%s resoure :%s " % (host, resource_stat)
    # 如果三次值的平均值大于报警阀值
    if sum([float(num) for num in resource_stat[resource_stat_key]]) / 3 > float(warn_dict[warn_dict_key]):
        if int(action_stat[resource_stat_key]) < 3:  # 报警次数小于3次
            temp_sms_message = "主机:%s" % host + resource_message[resource_stat_key][0] % warn_dict[warn_dict_key]
            # print temp_sms_message
            # 发送报警
            send_monitor(temp_sms_message)
            action_stat[resource_stat_key] += 1  # 每次报警都加1
    else:
        # 如果小于报警阀值且 报警状态不为0 则代表已经报过敬 现已恢复 即恢复状态 发送恢复通知短信
        if action_stat[resource_stat_key] != 0:
            action_stat[resource_stat_key] = 0
            temp_sms_message = "主机:%s" % host + resource_message[resource_stat_key][1]
            # 发送报警恢复通知
            send_monitor(temp_sms_message)


def exec_command(command):  # 执行命令  返回分别为系统负载 io等待 网络连接
    try:
        load_cmd = command + '"%s"' % "top -n1 -d1 -b | egrep -i '^top'"
        stat, s_load = commands.getstatusoutput(load_cmd)
        s_load = re.split(',|: ', s_load)[-3]
        s_load = float(s_load)

        iowait_cmd = command + '"%s"' % "top -n1 -d1 -b | egrep -i '^%cpu'"
        stat, s_iowait = commands.getstatusoutput(iowait_cmd)
        s_iowait = s_iowait.split()[-8]
        s_iowait = float(s_iowait)

        conn_cmd = command + '"%s"' % "ss -tna | egrep -i -v 'LISTEN|State' | wc -l"
        stat, conn_count = commands.getstatusoutput(conn_cmd)
        conn_count = int(conn_count)

        return [s_load, s_iowait, conn_count]
    except Exception, e:
        print "执行资源获取命令失败,错误代码:%s" % e
        return ['None', 'None', 'None']


if __name__ == '__main__':
    # 运行日志
    log_file = "monitor_load.txt"
    f = open(log_file, 'a')
    # 主机列表
    host_list = {"xx_xxxx": "ip:duankou",
                 "xx_xxxxx": "ip:duankou",
                 "xxx_xxxx": "ip:duankou",
                 "xx_xxxx": "ip:duankou", }

    # 主机key
    key_file = "/root/.ssh/xxxx_key"

    warn_dict = {'load': 5, 'iowait': 10, 'netconn': 14000}  # 报警阀值
    # 资源状态字典 每次取值都存到对应列表中 保留三次
    resource_init_stat = {'load': [0, 0, 0], 'iowait': [0, 0, 0], 'netconn': [0, 0, 0]}
    # 报警状态 默认为0 报警一次加1 超3次不报警 恢复后置0
    action_init_stat = {'load': 0, 'iowait': 0, 'netconn': 0}

    # 报警与恢复信息 列表第一个元素为异常时信息 第二个元素为正常时信息
    resource_message = {'load': ["[系统平均负载超过:%s,请及时关注]", "[系统平均负载超过]"],
                        'iowait': ["[系统io等待超过:%s,请及时关注]", "[io等待恢复正常]"],
                        'netconn': ["[系统网络连接数超:%s,请及时关注]", "[网络连接数恢复正常]"]}

    get_time = 1  # 多久取值一次
    count = 1  # 取值次数
    host_stat = {}  # 机器状态字黄
    while True:
        try:
            for host_name in host_list.keys():
                if host_name not in host_stat:
                    host_stat[host_name] = []
                    host_stat[host_name].append(copy.deepcopy(resource_init_stat))  # 第一个元素为 资源状态
                    host_stat[host_name].append(copy.deepcopy(action_init_stat))  # 第二个元素为 报警状态

                host_ip = host_list[host_name].split(":")[0]
                host_port = host_list[host_name].split(":")[1]
                cmd = 'ssh -o "StrictHostKeyChecking=no" -o "ConnectTimeout=3" -p %s -i %s root@%s ' % (
                    host_port, key_file, host_ip)
                status_result = exec_command(cmd)  # 系统负载 io等待 网络连接
                if status_result[0] == "None":
                    # 发送报警 获取失败
                    continue
                else:

                    # 取值 设相应的值 除3取模 确保每次都写相应的位置
                    index = (count % 3) - 1  # 资源状态值列表索引
                    # status_result = [6, 1.2, 48]   #  测试数据

                    # 报警处理
                    host_stat[host_name][0]['load'][index] = status_result[0]
                    host_stat[host_name][0]['iowait'][index] = status_result[1]
                    host_stat[host_name][0]['netconn'][index] = status_result[2]

                    # 检测是否需要报警  资源状态键值 阀值键值
                    action_check('load', 'load', host_stat[host_name][0], host_stat[host_name][1], host_name)
                    action_check('iowait', 'iowait', host_stat[host_name][0], host_stat[host_name][1], host_name)
                    action_check('netconn', 'netconn', host_stat[host_name][0], host_stat[host_name][1], host_name)

                    time.sleep(get_time)
                    count += 1
        except Exception, e:
            time.sleep(get_time)
            print "程序运行发生错误,错误代码:%s" % e
            count += 1
