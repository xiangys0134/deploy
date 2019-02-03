#!/bin/bash
#
http=$1
CODE=`curl -I -s --connect-timeout 5 ${http}|grep "HTTP"|cut -d" " -f2`

if [ "$CODE" == "200" ]; then
    echo "HTTP:${http} is running"
    echo "code:$CODE"
elif [ "$CODE" == "301" -o "$CODE" == "302" ]; then
    echo "code:$CODE"
else
    echo "HTTP:${http} is not running"
fi

