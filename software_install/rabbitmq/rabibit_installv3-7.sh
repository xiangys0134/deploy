#!/bin/bash
# Author: yousong.xiang
# Date:  2019.03.04
# Version: v1.0.1
# RabbitMQ3.7版本安装

[ -f /etc/profile ] && . /etc/profile

cmd=`dirname $0`

#检查网络状态
function env_check() {
    uid=$(id -u)
    if [ ${uid} -ne 0 ]; then
        echo '==此脚本需要root用户执行,程序即将退出.'
        exit 2        
    fi

    ping -c 1 -W 2 www.baidu.com >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo '==网络不通,请检查网络'
        exit 6
    fi 
}

#检查rpm包是否安装
function check_rpm() {
    rpm_pkg=$1
    num=`rpm -qa|grep ${rpm_pkg}|wc -l`
    echo ${num}
}


#关闭selinux
function selinux_stop(){
    sed -i '/^SELINUX=enforcing$/c\SELINUX=disabled' /etc/selinux/config
    setenforce 0
}


function erl_install() {
    num=`env_check epel-release`
    if [ "${num}" == "0" ]; then
        echo "epel-release install ..."
        yum install -y epel-release &>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "\033[32mInstall epel-release seccess\033[0m"
        else
            echo -e "\033[31mInstall epel-release failure\033[0m"
        fi
    fi

    if [ ! -f erlang-solutions-1.0-1.noarch.rpm ]; then
        wget http://packages.erlang-solutions.com/erlang-solutions-1.0-1.noarch.rpm
        if [ $? -ne 0 ]; then
            echo "erlang-solutions-1.0-1.noarch.rpm download faild "
            exit 4
        fi 
    fi
    
    rpm -Uvh erlang-solutions-1.0-1.noarch.rpm &>/dev/null

    rpm -y install erlang &>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "\033[31mInstall erlang faild\033[0m"
        exit 5
    fi
}


function rabbit_install(){
    rep_file=/etc/yum.repos.d/rabbitmq.repo
    if [ ! -f ${rep_file} ]; then
        cat >>${rep_file}<<EOF
[bintray-rabbitmq-server]
name=bintray-rabbitmq-rpm
baseurl=https://dl.bintray.com/rabbitmq/rpm/rabbitmq-server/v3.7.x/el/7/
gpgcheck=0
repo_gpgcheck=0
enabled=1
EOF
    fi

    yum install -y rabbitmq-server &>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "\033[31mInstall rabbitmq-server faild\033[0m"
    fi


}


