#!/bin/bash
#author:sb        
#version:1.0
#date:20190306
#目录、文件差异同步

function LIST(){
    list_path=$1
    list_name=$2
    log_name=$3
    backup_path=$4
    echo "Backup start time: ${list_path}/${list_name}" `date '+%Y-%m-%d %H:%M:%S'` >> ${log_name}
    if [ ! -d "${backup_path}/${list_name}" ]; then
        mkdir -p ${backup_path}/${list_name}
    fi
    if [ ! -d "${list_path}/${list_name}" ]; then
        echo "Faile: ${list_path}/${list_name} does not exist"
    else
        rsync -av --progress --delete ${list_path}/${list_name}/ ${backup_path}/${list_name}
        [[ $? != '0' ]] && echo "${list_path}/${list_name} backup faile" >> ${log_name} ||  echo "${list_path}/${list_name} backup success" >> ${log_name}
    fi
    echo "Backup end time: ${list_path}/${list_name}" `date '+%Y-%m-%d %H:%M:%S'` >> ${log_name}
    echo "======================================================================" >> ${log_name}
}

function FILE(){
    file_path=$1
    file_name=$2
    log_name=$3
    backup_path=$4
    echo "Backup start time: ${file_path}/${file_name}" `date '+%Y-%m-%d %H:%M:%S'` >> ${log_name}
    if [ ! -d "${backup_path}" ]; then
        mkdir -p ${backup_path}
    fi
    if [ ! -f "${file_path}/${file_name}" ]; then
        echo "Faile: ${file_path}/${file_name} does not exist"
    else
        \cp ${file_path}/${file_name} ${backup_path}/
        [[ $? != '0' ]] && echo "${file_path}/${file_name} backup faile" >> ${log_name} ||  echo "${file_path}/${file_name} backup success" >> ${log_name}
    fi
    echo "Backup end time: ${file_path}/${file_name}" `date '+%Y-%m-%d %H:%M:%S'` >> ${log_name}
    echo "======================================================================" >> ${log_name}
}

#FILE函数传参示例：FILE 源文件目录 源文件名称 日志记录文件 目标备份路径
FILE /home/austin.yang docker-compose.yml /gmfstorage_bak/bak/backup.log /gmfstorage_bak/bak/compose

#LIST函数传参示例：LIST 源目录路径 源目录名称 日志记录文件 目标备份路径
LIST /srv/docker/gitlab redis /gmfstorage_bak/bak/backup.log /gmfstorage_bak/bak
LIST /data/docker/gitlab postgresql /gmfstorage_bak/bak/backup.log /gmfstorage_bak/bak
LIST /data/docker mediawiki /gmfstorage_bak/bak/backup.log /gmfstorage_bak/bak
LIST /srv/docker/gitlab gitlab /gmfstorage_bak/bak/backup.log /gmfstorage_bak/bak
#LIST /gmfstorage/samba public /gmfstorage_bak/bak/backup.log /gmfstorage_bak/bak

/usr/bin/docker cp c3fb3d355b4c:/data/www/mediawiki-1.25.1/LocalSettings.php /gmfstorage_bak/bak/wiki_file/
/usr/bin/docker cp c3fb3d355b4c:/data/www/mediawiki-1.25.1/images /gmfstorage_bak/bak/wiki_file/
