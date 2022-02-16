#!/bin/bash
#
[ -f /etc/profile ] && . /etc/profile
dir_mysql=/tmp/sql
base_dir=`dirname $0`
user="root"
pass="数据库root密码"
base_dir=`dirname $0`

if [ $# -ne 1 ]; then
     echo "USAGE:$0 '$1'"
     exit 3
fi

sql_file() {
     source_data=$1
     mysql_backup=/data/backup/mysql
     #dir_mysql=/tmp/sql

     result=`echo ${source_data}|sed 's/[0-9]//g'`

     if [ -n "${result}" ]; then
         echo "Parameters are integers"
         exit 4
     fi

    if [ ! -d ${result} ]; then
         echo "The backup not exist"
         exit 5
    fi

    if [ ! -d ${dir_mysql} ]; then
         mkdir ${dir_mysql} -p
    else
       rm -rf ${dir_mysql} && mkdir ${dir_mysql} -p
    fi

    cd ${mysql_backup}

    #获取备份数据库,通过传参进行判断 例:gmf_bms-201901301842.sql.tar.gz  参数则为:201901301842
    ls -1 |grep ${source_data}|while read file
    do
        #将mysql备份目录/data/backup/mysql下的tar.gz文件解压成SQL文件存放至dir_mysql
        tar -zxf ${file} -C ${dir_mysql}
        if [ $? -eq 0 ]; then
            echo "${file} Transformation SQL files to ${dir_mysql}"
        else
            echo "${file} Transformation faild"
            exit 6
        fi
    done


}

sql_install() {
    source_data=$1
    if [ -f /tmp/sql.log ]; then
        rm -rf /tmp/sql.log
    fi

    if [ -f /tmp/init-data.log ]; then
        rm -rf /tmp/init-data.log
    fi 

    cd ${base_dir}

    #let secc_count=0 避免离线环境let无法使用情况改用$(())
    #let fail_count=0
    secc_count=0
    fail_count=0
    for i in `ls -1 ${dir_mysql}`
    do
        #echo ${i%.sql}
        db=${i%-${source_data}.sql}
        # create database....
        if [ ${db} != "init-data" ]; then
            mysql -u${user} -p${pass} -e "CREATE DATABASE IF NOT EXISTS \`${db}\`"
            if [ $? -eq 0 ]; then
                echo "Database create success: ${db}"
            else
                echo "Database create faild: ${db}"
            fi

            mysql -u${user} -p${pass} ${db}< ${dir_mysql}/$i |tee -a /tmp/sql.log
           if [  $? -eq 0 ]; then
               echo "${db} import success"
               #echo ${secc_count}
               #let secc_count=${secc_count}+1
               secc_count=$(($secc_count+1))
           else 
               echo "${db} import faild"
               #let fail_count=${fail_count}+1
               fail_count=$((${fail_count}+1))
           fi
        fi
        
        #mysql -u${user} -p${pass} ${db}<${dir_mysql}/$i |tee -a /tmp/init-data.log
    done

    echo  "\033[32mMySQL db import success:${secc_count}\033[0m" && echo  "\033[31mMySQL db import fail:${fail_count}\033[0m"
}

sql_file $*
sql_install $*
