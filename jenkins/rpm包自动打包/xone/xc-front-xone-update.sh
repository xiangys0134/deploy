#!/bin/bash
# yousong.xiang 250919938@qq.com
# 2019.5.10
# v1.0.1
# xc-front-xone包更新脚本

[ -f /etc/profile ] && . /etc/profile

base_dir=`pwd`
web_site_dir=/data
host_user=root

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
    
}

pkg_update
