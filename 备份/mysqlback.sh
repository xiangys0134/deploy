#!/bin/bash
##author:shaobo.zheng
##version:0.1
#date:20180730
#A:mysql database backup.
#ohter:建议每周早上2点开始备份

#定义用户名及密码
user=mysqldumper
userPWD='123456'
##GRANT SELECT, RELOAD, SUPER, LOCK TABLES ON *.* TO 'mysqldumper'@'localhost' identified by '请修改密码' ;

if [ ! -d /data/backup/mysql ]; then
    mkdir -p /data/backup/mysql
fi

#定义备份文件存放路径
bakDir='/data/backup/mysql'
mysql='/bin/mysql'
#定义日志文件
LogFile=$bakDir/mysqlbak.log
Now=$(date +"%Y%m%d%H%M")
#定义备份数据库
db=$(/bin/mysql -u$user -p$userPWD -e "show databases;"|egrep -v "sys|information_schema|Database|performance_schema|mysql")


cd $bakDir || exit

function log_record(){
        log_message=$1
        echo "$(date +"%Y-%m-%d %H:%M:%S") $log_message" >>$LogFile
        }

function backup_data(){
        dbname=$1;
        filename=$2;
        log_record "start dump $File "
        /bin/mysqldump -u $user -p$userPWD -F --databases $dbname --master-data=2 > $filename
        [[ $? != '0' ]] && log_record "Dump $File fail." ||  log_record "$dbname Backup Success"
}

function commpress_data(){
        log_record "start commpress $File to $File\.tar.gz"
        source_filename=$1
        dst_filename=$2
        tar czf $dst_filename $source_filename
        [[ $? == '0' ]] && rm $source_filename|| log_record "commpress_data $File $File\.tar.gz fail."
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

cd $bakDir && find $bakDir -name "*.tar.gz" -type f -mtime +7 | xargs rm > /dev/null 2>&1 exit
