#!/bin/bash
# ansible推送zabbix配置文件至远端服务器
# Author yousong.xiang 250919938@qq.com
# Date 2019.4.9
# v1.0.1
# $1-->定义参数[zabbix_agentd|md_service|process_sh]分别表示zabbix配置文件及开发日志监控脚本
# $2-->定义ansible host ip或者ansible组，支持独立ip地址推送及ansible组推送
# $3-->定义压缩包名(tar.gz解压后不能包含目录，同时必须与$1定义的参数匹配)
# 例：$0 md_service 192.168.0.215 md_service_maintenance-v1.5.0.tar.gz
[ -f /etc/profile ] && . /etc/profile

cmd=`pwd`
Now=$(date +"%Y%m%d%H%M")
md_server_dir=md_service_maintenance
sh_dir=monitor_sh

if [ $# -ne 3 ]; then
    echo "USAGE: \$1:IP \$2:Version \$3:hostname"
    exit 2
fi


function ansible_md_server() {
    process=$1
    hosts_group=$2
    package=$3

    if [ ! -f ${cmd}/${package} ]; then
        echo "${package} not exist"
        exit 5
    fi 
    ansible ${hosts_group} -m shell -a "mkdir -p /etc/zabbix/monitor_sh/${md_server_dir}" -s
    ansible ${hosts_group} -m shell -a "mv /etc/zabbix/monitor_sh/${md_server_dir} /tmp/${md_server_dir}_${Now}" -s
    if [ $? -ne 0 ]; then
        echo "ansible执行出错,请检查"
        exit 4
    fi
    
    ansible ${hosts_group} -m shell -a "mkdir -p /etc/zabbix/monitor_sh/${md_server_dir}" -s
    ansible ${hosts_group} -m copy -a "src=${cmd}/${package} dest=/tmp" -s
    ansible ${hosts_group} -m shell -a "tar -zxf /tmp/${package} -C /etc/zabbix/monitor_sh/${md_server_dir}/" -s
    
}


function ansible_agentd() {
    process=$1
    hosts_group=$2
    package=$3

    if [ ! -f ${cmd}/${package} ]; then
        echo "${package} not exist"
        exit 5
    fi
    ansible ${hosts_group} -m copy -a "src=${cmd}/${package} dest=/tmp" -s
    if [ $? -ne 0 ]; then
        echo "ansible执行出错,请检查"
        exit 4
    fi
    ansible ${hosts_group} -m shell -a "tar -zxf /tmp/${package} -C /etc/zabbix/zabbix_agentd.d/" -s
    if [ ${hosts_group} == "zabbix_pro_ubuntu" ]; then
        ansible ${hosts_group} -m shell -a '/etc/init.d/zabbix-agent restart' -s
    else
        ansible ${hosts_group} -m shell -a 'systemctl restart zabbix-agent.service' -s
    fi
}

function ansible_sh() {
    process=$1
    hosts_group=$2
    package=$3

    if [ ! -f ${cmd}/${package} ]; then
        echo "${package} not exist"
        exit 5
    fi
    ansible ${hosts_group} -m shell -a "mkdir -p /etc/zabbix/monitor_sh" -s
    if [ $? -ne 0 ]; then
        echo "ansible执行出错,请检查"
        exit 4
    fi
    ansible ${hosts_group} -m copy -a "src=${cmd}/${package} dest=/tmp" -s
    ansible ${hosts_group} -m shell -a "tar -zxf /tmp/${package} -C /etc/zabbix/monitor_sh" -s

}


if [ "$1" == "md_service" ]; then
    ansible_md_server $*
fi

if [ "$1" == "zabbix_agentd" ]; then
    ansible_agentd $*
fi

if [ "$1" == "process_sh" ]; then
    ansible_sh $*
fi

