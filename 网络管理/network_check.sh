#!/bin/bash
# 每5秒钟通过curl请求行情接口查看响应时间
# 返回的结果案例：0.012::0.038::0.081::0.081::27757.000  分别表示time_namelookup time_connect time_starttransfer time_total

[ -f /etc/profile ] && . /etc/profile
mms_url='http://mms.xuncetech.com:8006/quote/stock-brief?stock_id=000001.SH%2C399001.SZ%2C399006.SZ'

[ ! -f /tmp/curl_check.log ] && touch /tmp/curl_check.log

function network_check() {
    Now=$(date +"%Y-%m-%d %H:%M:%S")
    result_time=`curl -o /dev/null -s -w %{time_namelookup}::%{time_connect}::%{time_starttransfer}::%{time_total}::%{speed_download}"\n" "$mms_url" `
    if [ $? -ne 0 ]; then
       echo "$Now connect_faild">>/tmp/curl_check.log
    else 
       echo "$Now $result_time">>/tmp/curl_check.log
    fi
    sleep 5
}

while true
do
    network_check
done
