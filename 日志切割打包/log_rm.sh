#!/bin/bash
#目录日志清除
#Author: yousong.xiang
#Date:  2018.12.3
#Version: v1.0.1
#脚本传参示例：bash log_rm.sh /data/www/gmf_utility/storage/excel/uploads xls 3

[ -f /etc/profile ] && . /etc/profile

if [ $# -ne 3 ]; then
    echo "Usage: $0 logs_path file_name date_time"
    exit 2
fi


function rm_logs() {
    #文件名采用模糊匹配规则,例如：upload_5c0491cc141a1.xlsx 则${2}可以设置为xls xls为文件类型名称
    logs_path=$1
    file_name=$2
    date_time=$3
    time_date=`date '+%Y-%m-%d %H:%M:%S'`
    
    if [ ! -d ${logs_path} ]; then
        echo -e "\033[31m${logs_path} not exist\033[0m"
        exit 3
    fi 
    find ${logs_path} -name "*${file_name}*" -type f -mtime +${date_time} |xargs -I {} rm -rf {}
    #find ${logs_path} -name "*${file_name}*" -type f -mtime +${date_time} |xargs -I {} echo {}

    if [ $? -eq 0 ]; then
        echo "${time_date} file delete success" >> /tmp/rm_logs.log
    fi 
}

#删除日志
rm_logs $*

