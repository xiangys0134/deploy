#!/bin/bash
#功能:数据库备份
#yousong.xiang
#v1.0.2
. /etc/profile

#数据库用户名
##GRANT SELECT, RELOAD, SUPER, LOCK TABLES ON *.* TO 'dumper'@'localhost' identified by 're8Z3db57dltINJdWF5e&2fMu';
##flush privileges ;
dbuser='dumper'
#数据库用密码
dbpasswd='re8Z3db57dltINJdWF5e&2fMu'
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
echo "备份时间为${t_time},备份数据库表 ${dbname} 开始" >> ${logpath}/log.log

#获取数据库名
dbname=`mysql -u${dbuser} -p${dbpasswd} -e "show databases;" |egrep -v "Database|sys|information_schema|mysql|performance_schema"`

#正式备份数据库
for db in $dbname; do
  #source=`mysqldump -u ${dbuser} -p${dbpasswd} ${db}> ${logpath}/${db}${backtime}.sql` 2>> ${logpath}/mysqllog.log;
  mysqldump -u${dbuser} -p${dbpasswd} -F -B $db --master-data={1,2} --single-transaction --events |gzip> ${logpath}/${db}${backtime}.sql.gz 2>> ${logpath}/mysqllog.log
  #备份成功以下操作
  if [ "$?" == 0 ];then
    cd $datapath

    #删除七天前备份，也就是只保存7天内的备份
    #find $datapath -name "*.tar.gz" -type f -mtime +7 -exec rm -rf {} \; > /dev/null 2>&1
    find $datapath -name "*.gz" -type f -mtime +15 -exec rm -rf {} \; > /dev/null 2>&1
    echo "${t_time} 数据库 ${db} 备份成功!!" >> ${logpath}/mysqllog.log
  else
    #备份失败则进行以下操作
    echo "${t_time} 数据库 ${db} 备份失败!!" >> ${logpath}/mysqllog.log
  fi
done
