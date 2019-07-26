#!/bin/bash
# 一键安装zabbix-agent,仅支持centos7
# Author yousong.xiang 250919938@qq.com
# Date 2019.7.26
# v1.0.1
# 示例： $1--->zabbix服务器主机地址   $2--->agent主机名称(多台agent不能重复命名)

[ -f /etc/profile ] && . /etc/profile
noarch_rpm='https://soft.g6p.cn/deploy/rpm/x86_64/zabbix-release-3.4-1.el7.centos.noarch.rpm'

[ $# -ne 2 ] && {
                    echo -e "\033[31m传递参数有误\033[0m"
                    echo "USAGE: $0 {master|slave} {master_hostname|master_hostip}"
                    exit 9
                }

function env_check() {
    uid=$(id -u)
    if [ ${uid} -ne 0 ]; then
        echo '==此脚本需要root用户执行,程序即将退出.'
        exit 2        
    fi

    ping -c 4 -W 5 www.aliyun.com >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo '网络不通,请检查网络'
        exit 6
    fi 
}

function zabbix_conf(){
    server_name=$1
    zabbix_name=$2
    zabbix_conf=/etc/zabbix/zabbix_agentd.conf
    cat >${zabbix_conf}<< EOF
PidFile=/var/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=0
Server=$server_name       
ServerActive=$server_name
Hostname=$zabbix_name
Include=/etc/zabbix/zabbix_agentd.d/*.conf
Timeout=30
EOF

}

function zabbix_agent_install() {
    echo $1 $2
    rpm -ivh ${noarch_rpm}
    if [ $? -ne 0 ]; then
        echo "rpm install fail"
        exit 5
    fi
    yum install zabbix-agent -y
    if [ -f /etc/zabbix/zabbix_agentd.conf ]; then
        zabbix_conf $1 $2
        systemctl enable zabbix-agent.service
        systemctl start zabbix-agent.service
    fi
    
}


function firewall_cmd() {
    firewall-cmd --list-all &>/dev/null
    if [ $? -eq 0 ]; then
        firewall-cmd --zone=public --add-port=10050/tcp --permanent &>/dev/null
        firewall-cmd --reload &>/dev/null
    fi
}
zabbix_agent_install $1 $2
firewall_cmd
