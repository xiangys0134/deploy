#!/bin/bash
# author:Yusin Xiang
# version:0.1
# date:2021.5.31
# A:mysql database backup.
# ohter:建议每周早上2点开始备份,如需兼容utc时间则可以在0点20分进行备份
# 解压:gzip -d FILE
# MYSQL 8.0 xx.sh host port username password
# CREATE USER 'mysqldumper'@'%' IDENTIFIED BY '123456';
# GRANT SELECT, RELOAD, LOCK TABLES ON *.* TO 'mysqldumper'@'%';

[ -f /etc/profile ] && . /etc/profile

echo "\$1:"$1
echo "\$2:"$2
echo "\$3:"$3
echo "\$4:"$4
if [ $# -ne 4 ]; then
  echo "{USAGE: \$1,\$2,\$3,\$4}"
  exit 3
fi
#实例地址
host=$1
#实例端口
port=$2
#用户名及密码
username=$3
password=$4

#定义备份文件存放路径
bakDir='/data/backup/mysql'
mysql='/usr/bin/mysql'
#定义日志文件
log=$bakDir/mysqllog.log
#oss存储路径
s3_dir='s3://stl-ops-hk/mysql'
Now=$(date +"%Y%m%d%H%M")
instance=`echo ${host%%.*}`

if [ ! -d $bakDir ]; then
    mkdir -p $bakDir
fi

/usr/bin/mysql -h${host} -P${port} -u$username -p$password -e "show databases;" &>/dev/null
if [ $? -ne 0 ]; then
  echo "${Now} database connect timeout." >> $log
  exit 6
fi

#定义备份数据库
db=$(/usr/bin/mysql -h${host} -P${port} -u$username -p$password -e "show databases;"|egrep -v "chinadb|fxdb|hkdb|usadb|awsdms_control|test|sys|information_schema|Database|performance_schema|mysql")

if [ ! -d $bakDir ]; then
  mkdir -p $bakDir
fi

cd $bakDir

function backup_data() {
  dbname=$1;
  echo "${Now} start dump $dbname " >> $log
  /usr/bin/mysqldump -h${host} -P${port} -u$username -p$password --databases $dbname --single-transaction --set-gtid-purged=off |gzip > $dbname${Now}.sql.gz
  if [ $? -ne 0 ]; then
    echo "${Now} mysqldump $dbname fail." >> $log
  else
    echo "${Now} mysqldump $dbname Success." >> $log
  fi
}

#备份数据包推送至aws s3存储
function upload_s3() {
    dbname=$1
    if [ -z "${dbname}" ]; then
        return 4
    fi
    if [ ! -f $dbname${Now}.sql.gz ]; then
      return 5
    fi
    aws s3 ls  ${s3_dir}/${instance}/ &>/dev/null
    if [ $? -ne 0 ]; then
      aws s3 sync ../mysql ${s3_dir}/${instance}/
      echo "${Now} create ${s3_dir}/${instance}" >> $log
    fi
    aws s3 cp $dbname${Now}.sql.gz ${s3_dir}/${instance}/
    if [ $? -ne 0 ]; then
      echo "${Now} update $dbname${Now}.sql.gz ${s3_dir}/${instance} failed" >> $log
    fi
    sleep 2;
    echo "${Now} update $dbname${Now}.sql.gz ${s3_dir}/${instance} Success." >> $log
}

#删除s3 30天前的数据
function delete_s3_pkg() {
  day_30=2592000
  day_noe=`date +%s`
  aws s3 ls ${s3_dir}/${instance}/ |while read file
  do
    file_time=`echo  $file|awk '{print $1}'`
    tarname=`echo  $file|awk '{print $NF}'`
    if [ "$tarname" == "0" ]; then
      break
    else
      gz_name=${tarname:-failed.tar.gz}
    fi
    file_format=`date -d "$file_time" +%s`
    cal_format=$[${day_noe}-${file_format}]
    if [ $cal_format -gt $day_30 ]; then
      aws s3 rm $s3_dir/${instance}/${gz_name}
    fi
  done
}

for dbname in $db
do
  backup_data $dbname
  upload_s3 $dbname
  delete_s3_pkg
done
cat $log
