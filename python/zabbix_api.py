#!/usr/bin/env python
# -*- coding:utf-8 -*-

import json
import urllib.request,urllib.error,urllib.parse

class ZabbixApi:
    def __init__(self):
        self.__url = 'http://192.168.0.42/zabbix/api_jsonrpc.php'
        self.__user = 'Admin'
        self.__password = 'xunce2018'
        self.__header = {"Content-Type": "application/json-rpc"}
        self.__token_id = self.UserLogin()


    #登陆获取token
    def UserLogin(self):
        data = {
            "jsonrpc": "2.0",
            "method": "user.login",
            "params": {
                "user": self.__user,
                "password": self.__password
            },
            "id": 0,
        }
        return self.PostRequest(data)

    def PostRequest(self,args):
        print(args)
        request = urllib.request.Request(self.__url,json.dumps(args).encode('utf-8'),self.__header)
        result = urllib.request.urlopen(request)
        try:
            response = json.loads(result.read().decode('utf-8'))
            # print(response)
            return response['result']
        except Exception as e:
            raise e

    #主机列表
    def HostGet(self, hostid=None, hostip=None):
        data = {
            "jsonrpc": "2.0",
            "method": "host.get",
            "params": {
                "output": "extend",
                "selectGroups": "extend",
                "selectParentTemplates": ["templateid", "name"],
                "selectInterfaces": ["interfaceid", "ip"],
                "selectInventory": ["os"],
                "selectItems": ["itemid", "name"],
                "selectGraphs": ["graphid", "name"],
                "selectApplications": ["applicationid", "name"],
                "selectTriggers": ["triggerid", "name"],
                "selectScreens": ["screenid", "name"]
            },
            "auth": self.__token_id,
            "id": 1,
        }
        if hostid:
            data['params'] = {
                "output": "extend",
                "hostids": hostid,
                "sortfield": "name",
            }
        return self.PostRequest(data)

    #监控项列表
    def ItemGet(self,hostid=None, itemid=None):
        data = {
            "jsonrpc": "2.0",
            "method": "item.get",
            "params": {
                "output": "extend",
                "hostids": hostid,
                "itemids": itemid,
                "sortfield": "name"
            },
            "auth": self.__token_id,
            "id": 1,
        }
        return self.PostRequest(data)

    #图像列表
    def GraphGet(self,hostid=None,graphid=None):
        data = {
            "jsonrpc": "2.0",
            "method": "graph.get",
            "params": {
                "output": "extend",
                "hostids": hostid,
                "graphids": graphid,
                "sortfield": "name"
            },
            "auth": self.__token_id,
            "id": 1,
        }

        return self.PostRequest(data)

    # 历史数据
    def History(self, itemid, data_type):
        data = {
            "jsonrpc": "2.0",
            "method": "history.get",
            "params": {
                "output": "extend",
                "history": data_type,
                "itemids": itemid,
                "sortfield": "clock",
                "sortorder": "DESC",
                "limit": 30
            },
            "auth": self.__token_id,
            "id": 2
        }
        return self.PostRequest(data)


def main():
    zapi = ZabbixApi()
    token = zapi.UserLogin()
    # print(token)
    hosts = zapi.HostGet()
    print(hosts)


if __name__ == '__main__':
    main()
