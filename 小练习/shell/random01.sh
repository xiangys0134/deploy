#!/bin/ash
#

for i in {1..10}
do
    RADDOM=`cat /proc/sys/kernel/random/uuid|sed 's/-//g'`
    echo ${RADDOM}
done
