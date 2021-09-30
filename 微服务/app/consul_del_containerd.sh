#!/bin/bash
# consul删除安装
# Author yousong.xiang
# Date 2021.9.30
# v1.0.1

#k8s service负载地址
consul_address='node-expoter-consul.kube-ops:8500'

[ -f /etc/profile ] && . /etc/profile

yum install -y epel-release jq
yum install -y jq

function consul_del {
  CONSUL_NODES=$(curl -s -XGET http://${consul_address}/v1/catalog/nodes | jq -r '.[].Address')
  CONSUL_CRITICAL=$(curl -s -XGET http://${consul_address}/v1/health/state/critical | jq -r '.[].ServiceID')
  for critical in ${CONSUL_CRITICAL}

  do
    for consul_ip in ${CONSUL_NODES}
    do
        curl -s -XPUT http://${consul_ip}:8500/v1/agent/service/deregister/${critical} &> /dev/null
        echo "${critical} 已删除" >> consul_del-`date +%Y%m%d`.log
    done
  done
}

consul_del
