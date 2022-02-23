#!/bin/bash
# 功能: Linux进程检测管理
# yousong.xiang
# 2022.2.23
# v1.0.1

[ -f /etc/profile ] && . /etc/profile
t_time=`date '+%Y-%m-%d %H:%M:%S'`
check_log=/tmp/serviceProcess.log
#service服务检测
function serviceCheck() {
  service=$1
  if [ $# -ne 1 ]; then
    echo 'USAG: $1 {sentinel.service|mysqld.service}'
    exit 4
  fi

  pid_num=`systemctl status ${service}|grep -i 'active'|grep -w running|wc -l`
  if [ ${pid_num} -ne 1 ]; then
    echo "${t_time} ${service}服务状态检测异常!" >> ${check_log}
    forloops=2
    while [ ${forloops} -gt 0 ]
    do
      systemctl stop ${service}
      systemctl start ${service}
      if [ $? -eq 0 ]; then
        break;
      else
        forloops=$[forloops-1]
      fi
      sleep 1
    done
  fi
}

#进程检测应用
function processCheck() {
  process_str=$1
  process_start_str=$2
  if [ $# -ne 2 ]; then
    echo 'USAG: $1 {sentinel_string|mysqld_string},$2 {/usr/sbin/nginx -f /etc/nginx.conf|}'
    exit 4
  fi
  pid_num=`ps -ef|grep ${process_str}|grep -v 'grep'|wc -l`
  if [ ${pid_num} -eq 0 ]; then
    echo "${t_time} ${process_str}进程状态检测异常!" >> ${check_log}
    forloops=2
    while [ ${forloops} -gt 0 ]
    do
      ${process_start_str}
      if [ $? -eq 0 ]; then
        break
      else
        forloops=$[forloops-1]
      fi
      sleep 1
    done
  fi
}

function main() {
  echo '服务检测...'
  #Example1
  #serviceCheck mysqld.service

  #Example2
  #processCheck '/usr/sbin/nginx' '/usr/sbin/nginx'

}

main
