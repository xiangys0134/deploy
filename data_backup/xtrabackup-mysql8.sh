#!/bin/bash
# 功能:使用xtrabackup数据库备份,使用场景为localhost
# yousong.xiang
# 2021.9.1
# v1.0.1

[ -f /etc/profile ] && . /etc/profile

# mysql授权
#mysql> CREATE USER 'bkpuser'@'localhost' IDENTIFIED BY '1234565';
#mysql> GRANT BACKUP_ADMIN, PROCESS, RELOAD, LOCK TABLES, REPLICATION CLIENT ON *.* TO 'bkpuser'@'localhost';
#mysql> GRANT SELECT ON performance_schema.log_status TO 'bkpuser'@'localhost';
#mysql> GRANT SELECT ON performance_schema.keyring_component_status TO bkpuser@'localhost';
#mysql> FLUSH PRIVILEGES;

#备份包保留时间
keep_day=7
# 需在系统上useradd创建用户并设置密码
backup_user='bkpuser'
backup_passowd='123456'
backup_dir='/bak/xtrabackup/mysql'
bak_time=`date +%F`
history_day=`date -d "${keep_day} day ago" +%F`

uid=`id -u`
id ${backup_user} &>/dev/null
result=$?

if [ ${result} -ne 0 ] || [ ${uid} -ne 0 ]; then
  echo "系统用户${backup_user}不存在或当前使用用户非root!"
  exit 5
fi

if [ ! -d ${backup_dir} ]; then
  mkdir ${backup_dir} -p
fi

#每天只固定做一次备份，如果已经有备份了会先删除掉当天的备份，如不想删除当前历史包，可mv到其他目录保存
if [ -d ${backup_dir}/${bak_time} ]; then
  rm -rf ${backup_dir}/${bak_time}
else
  mkdir ${backup_dir}/${bak_time}
  chown ${backup_user}:${backup_user} ${backup_dir}/${bak_time}
fi

#热备份数据库，DML语句不受影响
xtrabackup --user=${backup_user} --password=${backup_passowd} --backup --no-server-version-check --target-dir=${backup_dir}/${bak_time}

if [ $? -ne 0 ]; then
  # 可告警或者本地写日志,当备份失败时直接跳出以保留历史备份数据
  echo "${bak_time} 备份失败">>${backup_dir}/mysqllog.log
  exit 6
else
  echo "${bak_time} 备份成功">>${backup_dir}/mysqllog.log
fi

#删除历史备份包
if [ -d ${backup_dir}/${history_day} ]; then
  rm -rf ${backup_dir}/${history_day}
fi
