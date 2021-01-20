#!/bin/bash
# ======================================================
# 脚本功能：微服务的统一启动、关闭、日志查看
# 创 建 人：冯冲
# 创建时间：2020/04/10 17:00
# 版    本：0.2
# 版本说明：增加非交互方式启动/停止全部程序参数
# ======================================================

#服务安装位置
base_dir="/data"

#服务列表，需要与目录的名字一致，顺序可自定义
#招商基金
#services="registry-service monitor-service config-service gateway-service oauth-service user-service file-service metadata-service xc-risk-service indicator-service quartz-service  XASC xc-store-service XPRD"
#公司
services="xc-osp/registry-service xc-osp/monitor-service xc-osp/config-service xc-osp/oauth-service xc-osp/user-service xc-osp/file-service xc-osp/quartz-service data-quality/data-quality-service indicator/indicator-service metadata/metadata-service XHE/xhe-service XMG/XASC XMG/XCOM XMG/XPRD XMG/XSTD xas inv-analysis/inv-analysis-service xc-cmf-service/xc-risk-service xc-osp/gateway-service"


PS3="Please select a number: "
start ()
{
$base_dir/$1/bin/run.sh restart
}
stop ()
{
$base_dir/$1/bin/run.sh stop
}
log ()
{
servs_log=`cat $base_dir/$1/config/logback-spring.xml |awk -v RS="</*file>" 'NR==2{print}'`
if [ "$(echo $servs_log|grep "LOG_")" != "" ]; then
 dir1=${1##*/}
 fn1=${dir1%-*}
 servs_log="/logs/${dir1}/${fn1}.log"
fi
if [ "$2" = "" ]; then
 tail -30 $servs_log
else
 tail -$2 $servs_log 
fi
}
all ()
{
  for i in `echo $services`
  do
  if [ "$action" = "restart" ]; then
  start $i
   sleep 3
  elif [ "$action" = "stop" ]; then
   stop $i
   sleep 2
  elif [ "$action" = "log" ]; then
   echo
   echo "##########  $i  ##########"
   echo
   sleep 1
   log $i $t2
   sleep 3
  else
   echo "Action error!"
  fi
  done
}
help ()
{
echo "Usage: zbzx.sh [start|restart|stop|log|-h] [all|行数|行数f]"
echo "options:"
echo "       start/restart     交互方式启动/重启全部程序"
echo "       stop              交互方式停止指定或全部程序"
echo "       log               交互方式查看指定或全部程序的日志最后30行(默认参数)"
echo "       log 100           交互方式查看指定或全部程序的日志最后100行"
echo "       log 100f          交互方式查看指定程序的日志最后100行后持续监听日志"
echo "       start/stop all    非交互方式启动/停止全部程序"
echo "       -h                显示本帮助"
echo
}

if [ "$1" = "" ]; then
 action=start #脚本不加参数的默认动作, log:查看日志   start/restart:启动/重启服务  stop:停止服务
else
 if [ "$1" = "start" ] || [ "$1" = "restart" ]; then
  action=restart
  if [ "$2" = "all" ]; then
    all
    exit 0
  fi
 elif [ "$1" = "stop" ]; then
  action=stop 
  if [ "$2" = "all" ]; then
    all
    exit 0
  fi
 elif [ "$1" = "log" ]; then
  action=log
 elif [ "$1" = "-h" ]; then
  help
  exit 0
 else
  help
  exit 0
 fi
fi
if [ "$2" != "" ]; then
 t2=$2
fi
echo
echo "###  $action $t2 the services  ###"
echo

select var in $services All quit
do
    case $var in
    All)
      all
      action=other
      exit
    ;;

    quit|Quit|QUIT)
      action=other
      exit
    ;;

    *)
      if [ "$var" != "" ]; then 
      if [ "$action" = "restart" ]; then
       start $var
      elif [ "$action" = "stop" ]; then
       stop $var    
      elif [ "$action" = "log" ]; then
       echo
       echo "##########  $var  ##########"
       echo 
       sleep 2
       log $var $t2
      elif [ "$action" = "other" ]; then
       exit
      else
       echo "Action error!"
      fi
      else
       echo "Input error,exit."
       exit
      fi

    esac
#    exit
done	 
