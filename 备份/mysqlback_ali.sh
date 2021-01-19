#!/bin/bash
##author:shaobo.zheng yousong.xiang
##version:0.1
#date:20180730
#A:mysql database backup.
#ohter:建议每周早上2点开始备份

#定义用户名及密码
user=opsadmin
userPWD='eyxbdSe1iE54k'
HOST='rm-bp2895l9u4l7901021.mysql.rds.aliyuncs.com'
##GRANT SELECT, RELOAD, SUPER, LOCK TABLES ON *.* TO 'mysqldumper'@'localhost' identified by '8Zb57luINJWFefMu' ;

if [ ! -d /data/backup/mysql ]; then
    mkdir -p /data/backup/mysql
fi

#定义备份文件存放路径
bakDir='/data/backup/mysql'
mysql='/usr/bin/mysql'
#定义日志文件
LogFile=$bakDir/mysqlbak.log
Now=$(date +"%Y%m%d%H%M")
#oss存储路径
oss_dir='oss://xc-backup/mms/mysql/'
#定义备份数据库
db=$(/usr/bin/mysql -h${HOST} -u$user -p$userPWD -e "show databases;"|egrep -v "test|sys|information_schema|Database|performance_schema|mysql")


cd $bakDir || exit

function log_record(){
        log_message=$1
        echo "$(date +"%Y-%m-%d %H:%M:%S") $log_message" >>$LogFile
        }

function backup_data(){
        dbname=$1;
        filename=$2;
        log_record "start dump $File "
        /usr/bin/mysqldump -h${HOST} -u $user -p$userPWD --databases $dbname --master-data=2 > $filename
        [[ $? != '0' ]] && log_record "Dump $File fail." ||  log_record "$dbname Backup Success"
}

function delete_oss_pkg() {
    cd ${bakDir}
    find ./ -name "*tar.gz" -mtime +15|awk -F '/' '{print $NF}'|while read file
    do
        file=${file:-"tmp_bak_redis"}
        ossutil64 rm ${oss_dir}${file}
        rm -rf ${file}
    done
}

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

    ossutil64 cp -r ${pkg_name} ${oss_dir} --update --maxupspeed 20480 --jobs=1 --parallel=1
    if [ $? -ne 0 ]; then
        return 5
    fi
}

function commpress_data(){
        log_record "start commpress $File to $File\.tar.gz"
        source_filename=$1
        dst_filename=$2
        tar czf $dst_filename $source_filename
        [[ $? == '0' ]] && rm $source_filename|| log_record "commpress_data $File $File\.tar.gz fail."
        upload_oss $dst_filename
}


if [[ -z $db ]] ; then  log_record "Get databases list is null." && exit 5; fi

for dbname in $db
do
File=$dbname-$Now.sql
backup_data $dbname $File
done


for dbname in $db
do
File=$dbname-$Now.sql
commpress_data $File $File\.tar.gz
done

log_record "--------------------------"
delete_oss_pkg
#cd $bakDir && find $bakDir -name "*.tar.gz" -type f -mtime +15 | xargs rm > /dev/null 2>&1 exit
