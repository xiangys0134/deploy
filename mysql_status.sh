#!/bin/bash
#
#监控mysql复制，20180123
[ -f /etc/profile ] && . /etc/profile
mysql_socket=/usr/local/mysql/mysql.sock
user=root
passwd=fdsfqmkoVSElks4ds3
Mysqlsql="mysql -u${user} -p${passwd} -S $mysql_socket"
mysql_status() {
SQLresult=`/usr/local/mysql/bin/mysql --defaults-extra-file=/usr/local/mysql/my.cnf -e "show slave status\G"|egrep "\<Slave_IO_Running\>|\<Slave_SQL_Running\>" |awk '{print $2}'`
REVELT=$?
if [  $REVELT -ne 0 ];then
echo 0
return 8
fi

SQLarray=($SQLresult)
if [ "${SQLarray[0]}" == "Yes" -a "${SQLarray[1]}" == "Yes" ];then
    echo 1
else
    echo 0
fi	
}
ipaddr=`ip addr |grep eth1 |grep inet |awk '{print $2}' |cut -d "/" -f 1`
let result=`mysql_status`
aliyuncli cms PutCustomMetric --MetricList "
[{'groupId': 45516,'metricName': 'mysql_repliction_status','dimensions': {'ip': '120.27.134.101:21504','source': 'root'},'type': 0,'values': {'value': $result}}]"
