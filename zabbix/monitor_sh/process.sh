#!/bin/bash
# 进程存活检查脚本
# Author yousong.xiang 250919938@qq.com
# Date 2019.03.14
# v1.0.1
[ -f /etc/profile ] && . /etc/profile

function ProcessCheck() {
    process=$1
    result=$(ps -ef|grep ${process}|egrep -v "grep|$0"|wc -l)
    if [ ${result} -ge 1 ]; then
        echo 1
    else
        echo 0
    fi
}

case $1 in
  nginx)
    result=`ps -ef|grep "nginx"|grep "master process"|egrep -v "grep|$0"|wc -l`
    if [ ${result} -ge 1 ]; then
        echo 1
    else
        echo 0
    fi
  ;;
  *)
    ProcessCheck $1
  ;;
esac
