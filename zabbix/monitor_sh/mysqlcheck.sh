#!/bin/bash
#
# mysql主从监控
# 2019.3.22
# v1.0.1

#对该用户设置相关权限 grant REPLICATION CLIENT ON *.* TO 'zabbix'@'localhost';
MysqlUser=zabbix
MysqlPass=Aa123456
MysqlPort=3306
Mysqlsql="mysql -u$MysqlUser -p$MysqlPass"

ARGS=1 
if [ $# -ne "$ARGS" ];then 
    echo "Please input one arguement:" 
    exit 5
fi 

function mysqlcheck(){
    case $1 in 
      "slavecheck")
        SQLresult=`$Mysqlsql -e "show slave status\G" 2>/dev/null |egrep "\<Slave_IO_Running\>|\<Slave_SQL_Running\>" |awk '{print $2}'`
        SQLarray=($SQLresult)
        if [ "${SQLarray[0]}" == "Yes" -a "${SQLarray[1]}" == "Yes" ];then
            echo 1
        else
            echo 0
        fi
      ;;
      *)
        echo "USAGE: slavecheck"
        exit 4
    esac
}

mysqlcheck $1
