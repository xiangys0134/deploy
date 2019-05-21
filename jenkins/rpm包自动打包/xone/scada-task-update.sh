#!/bin/bash
# yousong.xiang 250919938@qq.com
# 2019.5.10
# v1.0.1
# scada-task包更新脚本

[ -f /etc/profile ] && . /etc/profile

base_dir=`pwd`
path_dir=/data/code
web_site_dir=/data
host_user=root


function server_stop() {
    task_pid=`ps -ef|grep scada-task |egrep -v "grep|$0|scada-task-update"|awk '{print $2}'`
    if [ -z "${task_id}" ]; then
        echo "SERVER is stoping"
        return 2
    fi
    sudo kill -9 ${task_pid}
}

function server_start() {
    task_pid=`ps -ef|grep scada-task |egrep -v "grep|$0|scada-task-update"|awk '{print $2}'`
    if [ -n "${task_pid}" ]; then
        echo "SERVER is running"
        return 0
    else
        sudo ${web_site_dir}/scada-task/bin/run.sh start
        echo "SERVER is starting"
        return 0
    fi
}

function scada_update() {
    #source_pkg=$1

    cd /tmp/${JOB_NAME}_tmp
    tar_name=`ls *tar.gz 2>/dev/null |awk '{print $0}'`
    if [ -z "${tar_name}" ]; then
        echo "更新包获取失败"
        exit 4
    fi
    version=${tar_name%%.tar.gz}

    #echo "${version}"
    #tar -zxvf scada-task.15.tar.gz -C /tmp/aaa
    sudo tar -zxf ${tar_name} -C ${path_dir}
    if [ $? -ne 0 ]; then
        echo "Decompress failed"
        exit 3
    fi
    
    #copy config file
    if [ -d ${web_site_dir}/scada-task/config ]; then
        sudo /bin/cp -rf ${web_site_dir}/scada-task/config ${path_dir}/${version}/ 
        if [ $? -ne 0 ]; then
            echo "configs copy failed"
            exit 7
        fi
    else
        echo "请修改相关配置文件，路径：${web_site_dir}/scada-task/config"
    fi

    cd ${web_site_dir}
    [ -L scada-task -o -f scada-task ] && sudo rm -rf scada-task
    sudo ln -s ${path_dir}/${version} scada-task
    if [ $? -ne 0 ]; then
        echo "link failed"
        exit 4
    fi
    sudo mkdir -p ${web_site_dir}/scada-task/logs/scada-task
    echo "sudo chown -R ${host_user}. ${path_dir}/${version}"
    sudo chown -R ${host_user}. ${path_dir}/${version}
    echo "sudo chown -R ${host_user}. ${web_site_dir}/scada-task"
    sudo chown -R ${host_user}. ${web_site_dir}/scada-task
    echo "部署完成"
}

server_stop
scada_update
server_start

