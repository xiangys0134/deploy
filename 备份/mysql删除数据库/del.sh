#!/bin/bash
#
#
. /etc/profile
user="root"
pass="mysql.admin.pass"
db=`mysql -uroot -pmysql.admin.pass -e "show databases;"|egrep -v "Database|information_schema|performance_schema|mysql|test"`

for i in ${db}
do
    mysql -u${user} -p${pass} -e "drop database $i"
done
