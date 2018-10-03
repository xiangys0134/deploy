echo "kill old service ----> $1 "
pid=$(ps -ef | grep java |grep -P $1-'\d+' | cut -b 10-14)
kill -9 $pid
exit 0
