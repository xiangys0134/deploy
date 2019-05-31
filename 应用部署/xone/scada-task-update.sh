#!/bin/bash
# yousong.xiang 250919938@qq.com
# 2019.5.10
# v1.0.1
# scada-task包更新脚本
# 示例：$0 scada-task.14.tar.gz

[ -f /etc/profile ] && . /etc/profile

base_dir=`pwd`
path_dir=/data/code
web_site_dir=/data
user=root

if [ $# -ne 1 ]; then
    echo "USAGE:$0 XX.tar.gz"
    exit 1
fi

if [[ ! ("$1" =~ "tar.gz") ]]; then
    echo "$1 == XX.tar.gz"
    exit 2
fi

if [ ! -d ${path_dir} ]; then
    sudo mkdir -p ${path_dir}
fi
linkname=`ls -l /data/scada-task 2>/dev/null |awk '{print $NF}'`
source_pkg=$1
version=${source_pkg%%.tar.gz}

function server_stop() {
    task_pid=`ps -ef|grep scada-task |egrep -v "grep|$0|scada-task-update"|awk '{print $2}'`
    if [ -z "${task_pid}" ]; then
        echo "SERVER is stoping"
        return 2
    fi
    sudo kill -9 ${task_pid}
}

function server_start() {
    task_pid=`ps -ef|grep scada-task |egrep -v "grep|$0|scada-task-update"|awk '{print $2}'`
    if [ -n "${task_pid}" ]; then
        echo "SERVER is running"
    else
        sudo ${web_site_dir}/scada-task/bin/run.sh start
    fi
}

function scada_update() {
    sudo tar -zxf ${source_pkg} -C ${path_dir}
    if [ $? -ne 0 ]; then
        echo "Decompress failed"
        exit 3
    fi

    pkg_time=`date '+%Y%m%d%H%M%S'`
    des_path=${version}-${pkg_time}
    mv ${path_dir}/${version} ${path_dir}/${des_path}
    #copy config file
    if [ -d ${web_site_dir}/scada-task/config ]; then
        sudo /bin/cp -rf ${web_site_dir}/scada-task/config ${path_dir}/${des_path}/
        if [ $? -ne 0 ]; then
            echo "configs copy failed"
            exit 7
        fi
    else
        echo "请修改相关配置文件，路径：${web_site_dir}/scada-task/config"
    fi

    cd ${web_site_dir}
    [ -L scada-task -o -f scada-task ] && sudo rm -rf scada-task
    ln -sf ${path_dir}/${des_path} scada-task
    if [ $? -ne 0 ]; then
        echo "link failed"
        exit 4
    fi
    sudo chown -R ${user}. ${path_dir}/${des_path} && sudo chown -R ${user}. ${web_site_dir}/scada-task
    echo "部署完成"
}

function scada_same_update() {
    backtime=`date '+%Y%m%d%H%M%S'`    

    mv ${path_dir}/${version} ${path_dir}/${version}_${backtime} 

    sudo tar -zxf ${source_pkg} -C ${path_dir}
    if [ $? -ne 0 ]; then
        echo "Decompress failed"
        exit 3
    fi

    #copy config file
    if [ -d ${path_dir}/${version}_${backtime}/config ]; then
        sudo /bin/cp -rf ${path_dir}/${version}_${backtime}/config ${path_dir}/${version}/
        if [ $? -ne 0 ]; then
            echo "configs copy failed"
            exit 7
        fi
    else
        echo "请修改相关配置文件，路径：${web_site_dir}/scada-task/config"
    fi

    cd ${web_site_dir}
    [ -L scada-task -o -f scada-task ] && sudo rm -rf scada-task
    ln -sf ${path_dir}/${version} scada-task
    if [ $? -ne 0 ]; then
        echo "link failed"
        exit 4
    fi
    sudo chown -R ${user}. ${path_dir}/${version} && sudo chown -R ${user}. ${web_site_dir}/scada-task
    echo "部署完成"
}

server_stop
#if [ "${linkname}" == "${path_dir}/${version}" ]; then
#    scada_same_update
#else
#    scada_update
#
#fi

scada_update
server_start
