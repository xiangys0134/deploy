#!/bin/bash
# 功能:数据库备份
# yousong.xiang
# 2021.8.5
# v1.0.2

[ -f /etc/profile ] && . /etc/profile

#数据库用户名
#CREATE USER 'mysqldumper'@'localhost' IDENTIFIED BY '123456';
#GRANT SELECT, RELOAD, PROCESS, SUPER, LOCK TABLES ON *.* TO 'mysqldumper'@'localhost';
##flush privileges ;
dbhost='localhost'
dbuser='mysqldumper'
#数据库用密码
dbpasswd='123456'
#备份时间
backtime=`date '+%Y%m%d%H%M%S'`
t_time=`date '+%Y-%m-%d %H:%M:%S'`

#日志备份路径
logpath='/data/mysqlbakup'
#数据备份路径
datapath='/data/mysqlbakup'

if [ ! -d ${datapath} ];then
  mkdir ${datapath} -p
fi

#日志记录头部
echo "备份时间为${t_time},备份数据库表 ${dbname} 开始" >> ${logpath}/mysqllog.log

#获取数据库名
dbname=`mysql -h ${dbhost} -u${dbuser} -p${dbpasswd} -e "show databases;" |egrep -v "Database|sys|information_schema|mysql|performance_schema|awsdms_control|test"`

#正式备份数据库
for db in $dbname; do
  mysqldump -h ${dbhost} -u${dbuser} -p${dbpasswd} -F -B $db --source-data=2 --single-transaction |gzip> ${logpath}/${db}${backtime}.sql.gz 2>> ${logpath}/mysqllog.log
  #备份成功以下操作
  if [ "$?" == 0 ];then
    echo "${t_time} 数据库 ${db} 备份成功!!" >> ${logpath}/mysqllog.log
  else
    #备份失败则进行以下操作
    echo "${t_time} 数据库 ${db} 备份失败!!" >> ${logpath}/mysqllog.log
  fi
done

#删除七天前备份，也就是只保存7天内的备份
cd ${datapath:-/tmp}
find ${datapath:-/tmp/mysqlbakup} -name "*.gz" -type f -mtime +7 -exec rm -rf {} \; > /dev/null 2>&1
