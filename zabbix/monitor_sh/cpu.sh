#!/bin/bash
# CPU负载监控指标脚本
# Author yousong.xiang 250919938@qq.com
# Date 2019.03.15
# v1.0.1

[ -f /etc/profile ] && . /etc/profile

case $1 in
  arg1)
    result=`cat /proc/loadavg|awk '{print $1}'`
    echo ${result}
  ;;
  arg5)
    result=`cat /proc/loadavg|awk '{print $2}'`
    echo ${result}
  ;;
  arg15)
    result=`cat /proc/loadavg|awk '{print $3}'`
    echo ${result}
  ;;  
  *)
    echo "USAGE: arg1|arg5|arg15"
  ;;
esac
