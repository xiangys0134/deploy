#!/bin/bash
# 功能:mongodb数据库备份
# yousong.xiang
# 2022.1.10
# v1.0.1

# 用户授权
# use admin db.createUser({user:"dumper",pwd:"123456",roles:[{role:"readAnyDatabase",db:"admin"}]})

[ -f /etc/profile ] && . /etc/profile

host=172.20.21.163
port=27017
auth_db=admin
backup_db_list='fastbull_macro_data fastbull_media fastbull_news fastbull_quotes fastbull_universal'
username=dumper
password=emJIRFUuoynMhyOzf6P5

#备份时间
backtime=`date '+%Y%m%d%H%M%S'`

#数据备份路径
datapath='/data/mongodbbakup/bak'

if [ ! -d $datapath ]; then
  mkdir -p $datapath
fi

function mongodbBak {
  #set -eux
  backup_db=$1
  backup_path_dir=`echo ${datapath%/*}`
  out_dir=`echo ${datapath##*/}`
  cd $backup_path_dir
  mongodump \
    --host="${host}" \
    --port=${port} \
    --authenticationDatabase=${auth_db} \
    --db=${backup_db} \
    --out=${out_dir} \
    --username=${username} \
    --password=${password} \
    --forceTableScan
  cd -
  #set +eux
}

function compressGzip {
  set -eux
  backup_db=$1
  cd ${datapath:-/tmp}
  if [ -d $backup_db ]; then
      tar -czf ../${backup_db}-${backtime}.tar.gz $backup_db --remove-files
      echo "${backtime} 数据库 ${backup_db} 备份成功!!" >> /tmp/mongobbak.log
  else
      echo "${backtime} 数据库 ${backup_db} 备份失败!!" >> /tmp/mongobbak.log
  fi	  
  cd -
  set +eux
}

function removeGzip {
  backup_path_dir=`echo ${datapath%/*}`
  cd ${backup_path_dir:-/tmp}
  find ${backup_path_dir:-/tmp/mongodbbakup} -name "*.gz" -type f -mtime +3 -exec rm -rf {} \; > /dev/null 2>&1
}

function main {
  for db in ${backup_db_list}
  do
    mongodbBak $db
    compressGzip $db
  done
  removeGzip
}

main
