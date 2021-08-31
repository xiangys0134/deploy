#!/bin/bash
# fazzaco app状态检测
# Author: yousong.xiang
# Date:  2021.2.5
# Version: v1.0.1
#----------端口列表信息-----------
# frontend: 11084
# backend-sys-service:  11024
# common-service: 10074
# frontend:   13084
# gateway:    15084
# web-api:    16084

host_ip='127.0.0.1'
url='actuator/health'
#service_all_ports<-->service_all_app 如果新增端口或者app应用则需要修改变量值service_all_ports、service_all_app
service_all_ports="11084 11024 10074 13084 15084 16084"
service_all_app="fazzaco-app-frontend-service fazzaco-backend-sys-service fazzaco-common-service fazzaco-frontend fazzaco-gateway fazzaco-web-api"
log_message='/tmp/service-check.log'
JAVA_OPTS="/usr/local/jdk/bin/java -jar -Xmx1500m -Xms1500m -Xmn600m"
APP_HOME="/usr/local/jar"
APP_LOG="/usr/local/jar/logs"
cmd_dir=`pwd`

if [ $# -lt 1 ]; then
  echo "USAGE:{11084|11024|10074|13084|15084|16084}"
fi

[ -f /etc/profile ] && . /etc/profile

function service_start {
  port=$1
  app=$2
  datetime=`date '+%Y-%m-%d %H:%M:%S'`
  code=`curl -I --connect-timeout 5 -o /dev/null -s -w %{http_code} ${host_ip}:${port}/${url}`
  if [ "$code" != "200" ]; then
    #检测失败则启动jar包程序
    process_id=`ps -ef|grep -w ${app}|egrep -v "grep"|tail -1|awk '{print $2}'`
    kill -9 ${process_id}
    sleep 1
    #启动服务
    sudo nohup  ${JAVA_OPTS} ${APP_HOME}/${app}.jar \
    --spring.profiles.active=ge >> ${APP_LOG}/${app}.log \
    2>&1 &
    #
    if [ $? -ne 0 ]; then
      echo "${datetime} ${app} start failed." >> ${log_message}
    else
      echo "${datetime} ${app} start successful." >> ${log_message}
    fi
    sleep 2
  fi
}

function service_check {
  #检测传参端口是否合法
  port=$1
  echo "${service_all_ports}"|grep -w ${port} &>/dev/null
  if [ $? -ne 0 ]; then
    return 4
  fi
  flag=0
  for i in ${service_all_ports}
  do
    if [ "${port}" == "$i" ]; then
      app_flag=${flag}
      break
    fi
    flag=$((flag+1))
  done

  flag=0
  for app in ${service_all_app}
  do
    if [ "${flag}" == "${app_flag}" ]; then
      app_service=${app}
      break
    fi
    flag=$((flag+1))
  done

  #传参
  service_start ${port} ${app_service}
}

#获取脚本传参列表
for i in $@
do
  service_check $i
done
