#!/bin/bash
#
# yum install -y nc
declare -x i=2

if [ -f /tmp/true.txt ]; then
    rm -rf /tmp/true.txt
fi

if [ -f /tmp/flase.txt ]; then
    rm -rf /tmp/flase.txt
fi

until [ $i -eq 255 ];do
    ping -c 1 -W 1 192.168.0.$i &>/dev/null
    result1=$?

    nc -v -w 1 192.168.0.$i -z 31235 &>/dev/null
    result2=$?

    nc -v -w 1 192.168.0.$i -z 3389 &>/dev/null
    result3=$?
   
    if [ $result1 -eq 0 -o $result2 -eq 0 -o $result3 -eq 0 ]; then
        echo -e "ip is up\033[32m 192.168.0.$i\033[0m" && echo "192.168.0.$i" >> /tmp/true.txt
    else
        echo -e  "ip is down\033[31m 192.168.0.$i\033[0m" && echo "192.168.0.$i" >> /tmp/flase.txt
    fi

    i=$(($i+1))
done
