#!/bin/bash
# 添加zabbix agent监控
# Author yousong.xiang 250919938@qq.com
# Date 2019.4.9
# v1.0.1
# $1--->zabbix agent host ip
# $2--->zabbix version 目前只配置4.0版本
# $3--->zabbix hostname
# 例：add_zabbixagent.sh 10.10.0.240 4.0 pro_python1

[ -f /etc/profile ] && . /etc/profile

cmd=`pwd`

if [ $# -ne 3 ]; then
    echo "USAGE: \$1:IP \$2:Version \$3:hostname"
    exit 3
fi

if [ "$2" != "3.4" -o "$2" != "4.0" -o "$2" != "4.2" ]; then
    echo "zabbix 版本为：3.4|4.0|4.2"
fi  

if [ "$2" == "3.4" ]; then
    rpm_url='https://repo.zabbix.com/zabbix/3.4/rhel/7/x86_64/zabbix-release-3.4-2.el7.noarch.rpm'
fi

if [ "$2" == "4.0" ]; then
    rpm_url='http://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-release-4.0-1.el7.noarch.rpm'
fi

if [ "$2" == "4.2" ]; then
    rpm_url='https://repo.zabbix.com/zabbix/4.2/rhel/7/x86_64/zabbix-release-4.2-1.el7.noarch.rpm'
fi

host_str=`echo "$3"|sed 's/[a-z0-9_]//g'`
if [ ${host_str} != "" ]; then
    echo "hostname为小写字母数字或下划线"
    exit 2
fi 

function ansible_add() {
    host_ip=$1
    rpm_pack=${rpm_url}
    hostname=$3
    zabbix_config=/etc/zabbix/zabbix_agentd.conf
    tmp_config=/tmp/zabbix_agentd.conf

    ansible ${host_ip} -m shell -a "rpm -ivh ${rpm_pack}" -s
    if [ $? -ne 0 ]; then
        echo "ansible执行出错,请检查"
        exit 4
    fi

    ansible ${host_ip} -m shell -a 'yum -y install yum-utils' -s
    ansible ${host_ip} -m shell -a 'yum-config-manager --enable rhel-7-server-optional-rpms' -s
    if [ $? -ne 0 ]; then
        echo "yum-config-manager执行出错,请检查"
        exit 5
    fi

    ansible ${host_ip} -m shell -a 'yum install -y zabbix-agent' -s
    if [ $? -ne 0 ]; then
        echo "zabbix agent安装失败"
        exit 6
    fi
    
    ansible ${host_ip} -m shell -a "mv ${zabbix_config} /etc/zabbix/zabbix_agentd.confbak" -s
    #ansible ${host_ip} -m shell -a "
 cat >${tmp_config}<< EOF
PidFile=/var/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=0
Server=172.16.0.205
Hostname=${hostname}
Include=/etc/zabbix/zabbix_agentd.d/*.conf
Timeout=30
EOF
    ansible ${host_ip} -m copy -a "src=${tmp_config} dest=/tmp" -s
    ansible ${host_ip} -m shell -a "cp /tmp/zabbix_agentd.conf ${zabbix_config}" -s
    ansible ${host_ip} -m shell -a 'systemctl restart zabbix-agent.service' -s
    ansible ${host_ip} -m shell -a 'systemctl enable zabbix-agent.service' -s
}

function firewalld() {
    firewall-cmd --list-all &>/dev/null
    if [ $? -eq 0 ]; then
        firewall-cmd --zone=public --add-port=10050/tcp --permanent &>/dev/null
        firewall-cmd --reload &>/dev/null
    fi
}

ansible_add $*
firewalld
