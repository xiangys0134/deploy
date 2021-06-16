#!/bin/bash
# Yusin Xiang
# 2021.6.9
# v1.0.1
# redis添加白名单ip

[ -f /etc/profile ] && . /etc/profile

white_ip='
18.166.216.136
18.166.210.12
3.65.178.130
35.156.203.226
3.67.83.136
3.67.84.165
3.65.199.160
3.123.41.60
3.66.215.143
3.127.229.183
52.59.195.173
18.196.32.118
18.157.85.195
18.193.47.86
'

redis_cmd='redis-cli -h 127.0.0.1'

#过滤重复ip,redis中key：white_ip 固定
redis_ip=`$redis_cmd LRANGE white_ip 0 -1`
for ip in $white_ip
do
  echo ${redis_ip:-nullvalue} |grep $ip &>/dev/null
  if [ $? -ne 0 ]; then
    $redis_cmd LPUSH white_ip $ip
    echo "redis添加列表值： $ip"
  fi
done
