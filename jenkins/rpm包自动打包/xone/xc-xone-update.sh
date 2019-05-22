#!/bin/bash
# yousong.xiang 250919938@qq.com
# 2019.5.21
# v1.0.1
# xc-xone包更新脚本

[ -f /etc/profile ] && . /etc/profile

base_dir=`pwd`
host_user=root

function server_stop() {
    process_sum=`ps -ef|grep xc-xone|egrep -v "grep|$0|xone_start"|wc -l`
    if [ ${process_sum} -eq 0 ]; then
        return 0
    fi
    ps -ef|grep xc-xone|egrep -v "grep|$0|xone_start"|awk '{print "kill -9 "$2}'|bash
}

function server_start() {
cd /data/xc-xone

sudo bash ./regitry-server/bin/run.sh start
sleep 10
#checkport 8761

sudo bash ./monitor-service/bin/run.sh start
sleep 10
#checkport 8765

sudo bash ./config-server/bin/run.sh start
sleep 10
#checkport 8763

sudo bash ./gateway/bin/run.sh start
sleep 10
#checkport 8762

sudo bash ./tm-service/bin/run.sh start
sleep 10
#checkport 7970

sudo bash ./file-service/bin/run.sh start
sleep 10
#checkport 8768

sudo bash ./oauth-service/bin/run.sh start
sleep 10
#checkport 8766

sudo bash ./user-service/bin/run.sh start
sleep 10
#checkport 8764

sudo bash ./bond-service/bin/run.sh start
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
    if [ -z "${pkg_name}" ]; then
        echo "更新包获取失败"
        return 4
    fi

    echo "rpm -Uvh ${pkg_name} --force"
    sudo rpm -Uvh ${pkg_name} --force
    if [ $? -ne 0 ]; then
        echo "rpm Uvh failed"
        return 3
    else
        echo "rpm Uvh success"
        return 0
    fi
}  

server_stop
pkg_update
server_start


