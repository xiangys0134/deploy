#!/bin/bash
# author:yousong.xiang 2018.10.29
# v1.0.1
#CentOS7安装fluentd插件
#
[ -f /etc/profile ] && . /etc/profile
cmd=`pwd`

function check_user() {
    user_id=`id -u`
    if [ ${user_id} -ne 0 ]; then
        echo "\033[31mUsers are not root\033[0m"
        exit 7
    fi
}

function check_rpm() {
    rpm_name=$1
    num=`rpm -qa|grep ${rpm_name}|wc -l`
    echo ${num}
}

function install_rpm() {
    sed -i '/^SELINUX=/c\SELINUX=disabled' /etc/sysconfig/selinux
    yum -y install zlib-devel libcurl-devel
    wget http://packages.treasuredata.com.s3.amazonaws.com/3/redhat/7/x86_64/td-agent-3.2.0-0.el7.x86_64.rpm
    if [ $? -ne 0 ]; then
        echo -e "\033[31mtd-agent-3.2.0-0.el7.x86_64.rpm download failure\033[0m"
        exit 6
    else
        echo -e "\033[32mtd-agent-3.2.0-0.el7.x86_64.rpm download success\033[0m"
    fi

    if [ `check_rpm redhat-lsb-core` -eq 0 ]; then
        echo -e "\033[32mredhat-lsb-core ready to install...\033[0m"
        yum -y install redhat-lsb-core
    fi

    if [ `check_rpm td-agent` -eq 0 ]; then
        rpm -ivh td-agent-3.2.0-0.el7.x86_64.rpm
    fi 
   
    sed -i -e '/^User=/c\User=root' -e '/^Group=/c\Group=root' /lib/systemd/system/td-agent.service
    systemctl daemon-reload

    [ -f ${cmd}/td-agent-3.2.0-0.el7.x86_64.rpm ] && rm -rf ${cmd}/td-agent-3.2.0-0.el7.x86_64.rpm
    
    echo -e "\033[32mstart up td-agent.service...\033[0m"
    systemctl restart td-agent.service 
}



install_rpm 

