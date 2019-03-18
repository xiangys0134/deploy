#!/bin/bash
# PING网络检查脚本
# Author yousong.xiang 250919938@qq.com
# Date 2019.03.13
# v1.0.1

[ -f /etc/profile ] && . /etc/profile

if [ $# -ne 1 ]; then
    echo "USAGE: $0 args[1]"
fi

ping="ping -c 2 -W 4 "

function AgentPing() {
    host=$1
    ${ping} ${host} &>/dev/null
    if [ $? -eq 0 ]; then
        echo 1
    else
        echo 0
    fi

}

AgentPing $*
