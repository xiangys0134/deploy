#!/bin/bash
# yousong.xiang 250919938@qq.com
# 2019.5.21
# v1.0.1
# xc-xone包更新脚本

[ -f /etc/profile ] && . /etc/profile

base_dir=`pwd`
host_user=root

function server_stop() {
    ps -ef|grep xc-xone|egrep -v "grep|$0|xone_start"|awk '{print "kill -9 "$2}'|bash
}

function server_start() {
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
}

function pkg_update() {
    cd /tmp/${JOB_NAME}_tmp
    pkg_count=`ls *rpm 2>/dev/null |awk '{print $0}'|wc -l`
    if [ ${pkg_count} -ne 1 ]; then
        echo "rpm error"
        return 6
    fi
    pkg_name=`ls *rpm 2>/dev/null |awk '{print $0}'`
    if [ -z "${tar_name}" ]; then
        echo "更新包获取失败"
        return 4
    fi

    sudo rpm -Uvh ${pkg_name} --force
    if [ $? -ne 0 ]; then
        echo "rpm Uvh failed"
        return 3
    else
        echo "rpm Uvh success"
        return 0
    fi
  

server_stop
pkg_update
server_start


