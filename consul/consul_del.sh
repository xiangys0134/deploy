#!/bin/bash
# baiyongjie 2019-06-25

# 获取consul的地址
CONSUL_INGRESS=`kubectl get ingresses.extensions --all-namespaces | grep consul | awk '{print $4}'`

test -d logs || mkdir logs

for consul_address in ${CONSUL_INGRESS}
do

    echo "------------------" >> logs/`date +%Y%m%d`.log
    echo "当前consul为${consul_address}" >> logs/`date +%Y%m%d`.log
    CONSUL_NODES=$(curl -s -XGET http://${consul_address}/v1/catalog/nodes | jq -r '.[].Address')
    CONSUL_CRITICAL=$(curl -s -XGET http://${consul_address}/v1/health/state/critical | jq -r '.[].ServiceID')
    for critical in ${CONSUL_CRITICAL}
    do

        echo "${critical} 已删除" >> logs/`date +%Y%m%d`.log
        for consul_ip in ${CONSUL_NODES}
        do
            curl -s -XPUT http://${consul_ip}:8500/v1/agent/service/deregister/${critical} &> /dev/null
        done

    done
done
