#!/bin/bash
# Description: Redis备份
# Author: yousong.xiang 
# Date: 20189.5.5
# version: v1.0.1

[ -f /etc/profile ] && . /etc/profile

BAK_DIR='/data/backup/redis'
SRC_DIR='/var/lib/redis'
CMD_DIR=`pwd`
OSS_DIR='oss://test-backup/mms/redis/'

if [ ! -d ${BAK_DIR} ]; then
    mkdir -p ${BAK_DIR}
fi

#备份数据包推送至oss存储函数
function upload_oss() {
    pkg_name=$1
    if [ -z "${pkg_name}" ]; then
        return 4
    fi
    ossutil64 ls ${oss_dir} &>/dev/null
    if [ $? -ne 0 ]; then
        echo "directory query failed"
        return 3
    fi

    ossutil64 cp -r ${pkg_name} ${OSS_DIR} --update --maxupspeed 5048 --jobs=1 --parallel=1
    if [ $? -ne 0 ]; then
        return 5
    fi 
}

function delete_oss_pkg() {
    cd ${BAK_DIR}
    find ./ -name "*tar.gz" -mtime +15|awk -F '/' '{print $NF}'|while read file
    do
        file=${file:-"tmp_bak_redis"}
        #echo ${file}
        ossutil64 rm ${OSS_DIR}${file}
        #echo "ossutil64 rm oss://xc-backup/release/tmp_redis/${file}"
        rm -rf ${file}
    done    
}

function back_redis() {
    cd ${BAK_DIR}
    start_time=$(date '+%Y-%m-%d %H:%M:%S')
    bak_time=$(date '+%Y%m%d%H%M')
    echo "$(date '+%Y-%m-%d %H:%M:%S')    redis开始备份" >> redis_bak.log
    ls -1 ${SRC_DIR} |grep rdb &>/dev/null
    if [ $? -ne 0 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S')    无rdb存储文件" >> redis_bak.log
        return 3
    fi
    if [ -d tmp_redis ]; then
        rm -rf tmp_redis
    fi

    mkdir tmp_redis
    cp ${SRC_DIR}/*rdb ${BAK_DIR}/tmp_redis
    tar -czf redis_${bak_time}.tar.gz tmp_redis

    if [ $? -ne 0 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S')    rdb存储备份失败" >> redis_bak.log
        return 5
    fi 
    echo "$(date '+%Y-%m-%d %H:%M:%S')    redis结束备份" >> redis_bak.log

    upload_oss redis_${bak_time}.tar.gz    
    #find ${BAK_DIR} -name "*tar.gz" -type f -mtime +15 -exec rm -rf {} \; > /dev/null 2>&1
}

back_redis
delete_oss_pkg
