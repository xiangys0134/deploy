#!/bin/bash
# yousong.xiang 250919938@qq.com
# 2019.5.14
# v1.0.1
# xone服务启动脚本

function checkport()
{
    PORT=$1
    while [ `netstat -an|grep ${PORT}|grep LISTEN|wc -l` -lt 1 ]
        do
          echo '端口'${PORT}'尚未建立侦听，等待'
          sleep 10
        done
}

ps -ef|grep xc-xone|egrep -v "grep|$0|xone_start"|awk '{print "kill -9 "$2}'|bash

cd /data/xc-xone

./regitry-server/bin/run.sh start
sleep 10
#checkport 8761

./monitor-service/bin/run.sh start
sleep 10
#checkport 8765

./config-server/bin/run.sh start
sleep 10
#checkport 8763

./gateway/bin/run.sh start
sleep 10
#checkport 8762

./tm-service/bin/run.sh start
sleep 10
#checkport 7970

./file-service/bin/run.sh start
sleep 10
#checkport 8768

./oauth-service/bin/run.sh start
sleep 10
#checkport 8766

./user-service/bin/run.sh start
sleep 10
#checkport 8764

./bond-service/bin/run.sh start
sleep 10
#checkport 8767
