#!/bin/bash
# oss测试上传下载脚本
# Author yousong.xiang 250919938@qq.com
# Date 2019.4.28
# v1.0.1
# 使用ossutil工具实现上传/下载,mysql备份数据库示例：market_quote-201904280521.sql.tar.gz

[ -f /etc/profile ] && . /etc/profile

cmd=`pwd`
bakDir='/data/backup/mysql'
dst_dir='oss://xc-backup/mms/mysql'
user='root'
userpass='123456'

if [ -d /tmp/mysql_tmp ]; then
    rm -rf /tmp/mysql_tmp
    mkdir -p /tmp/mysql_tmp
fi

if [ ! -d /data/backup/mysql_source ]; then
    mkdir -p /data/backup/mysql_source
fi


function mysql_mark() {
    #$1-----路径
    #$2-----模糊匹配包名
    #示例：mysql_file=`ossutil64 ls oss://xc-backup/mms/mysql|egrep "^[0-9]{4}-"|egrep "market_quote"|grep 20190428|awk '{print $NF}'|tail -1 2>&1`
    sql_url=$1
    sql_pkg=$2
    mysql_file=`ossutil64 ls ${sql_url}|egrep "^[0-9]{4}-"|egrep "${sql_pkg}"|grep $(date +"%Y%m%d")|awk '{print $NF}'|tail -1 2>&1`

    if [ "${mysql_file}" == "" ]; then
        echo "获取mysql数据库源失败"
        echo "$(date +"%Y-%m-%d %H:%M:%S") 获取mysql数据库源失败" >> /data/backup/mysql_source/mysql_import.log
        return 4
    fi
    
    cd /tmp/mysql_tmp
    ossutil64 cp ${mysql_file} /tmp/mysql_tmp
    if [ $? -ne 0 ]; then
        echo "下载mysql数据库源失败"
        echo "$(date +"%Y-%m-%d %H:%M:%S") 下载mysql数据库源失败" >> /data/backup/mysql_source/mysql_import.log
        return 5
    fi
} 


function mysql_import() {
    cd /tmp/mysql_tmp
    ls -1|while read file
    do
        if [ "${file}" == "" ]; then
             echo "${file}数据源不存在"
             echo "$(date +"%Y-%m-%d %H:%M:%S") ${file}数据源不存在" >> /data/backup/mysql_source/mysql_import.log
             continue
        fi
        tar -zxf ${file}
        if [ $? -ne 0 ]; then
            echo "${file}数据源解压失败"
            echo "$(date +"%Y-%m-%d %H:%M:%S") ${file}数据源解压失败" >> /data/backup/mysql_source/mysql_import.log
            continue
        fi
        
        mysql -u"${user}" -p"${userpass}"< ${file%%.tar.gz}
        if [ $? -ne 0 ]; then
            echo "${file%%.tar.gz}数据库导入失败"
            echo "$(date +"%Y-%m-%d %H:%M:%S") ${file%%.tar.gz}数据库导入失败">>/data/backup/mysql_source/mysql_import.log
            continue
        fi
    done
    
}


function sqlpkg_backup() {
    cd /tmp/mysql_tmp
    pkg_count=`ls -1|grep *tar.gz|wc -l`
    if [ ${pkg_count} -ge 1 ]; then
        ls -1|grep *tar.gz|while read pkg
        do
            mv -f ${pkg} /data/backup/mysql_source/
        done
    fi

}
