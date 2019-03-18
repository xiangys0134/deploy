#!/bin/bash
# Redis状态及info信息监控脚本
# Author yousong.xiang 250919938@qq.com
# Date 2019.03.13
# v1.0.1

[ -f /etc/profile ] && . /etc/profile

REDIS="redis-cli"

if [ $# -ne 4 ]; then
    echo "input error"
    exit 9 
fi

HOST=$1
PORT=$2
PASS=$3
CURRENT=$4

#以下为兼容redis无密码状态，传参值为null则赋值为''
if [ "${PASS}" == "null" ]; then
    PASS=
fi

RESULT=`${REDIS} -h ${HOST} -p ${PORT} -a "${PASS}" ping |grep -c PONG `
if [ ${RESULT} -ne 1 ]; then
    echo "Redis Error"
    exit 7
fi


function RedisStatus() {
    REDIS_CLI="${REDIS} -h ${HOST} -p ${PORT} -a \"${PASS}\" info"
    result=`${REDIS_CLI}|grep -w ${CURRENT}| awk -F':' '{print $2}'`
    echo ${result}

}

#
case $4 in
  used_memory_human)
    result=`RedisStatus $*`
    # 以下分别写入三种条件判断，因为结果唯一，可以这么写，之后再优化
    M_CODE=`echo ${result}|grep -i m |wc -l`
    G_CODE=`echo ${result}|grep -i g |wc -l`
    K_CODE=`echo ${result}|grep -i k |wc -l`

   if [ "${M_CODE}" == "1" ]; then
       code=`echo ${result}|awk -F '.' '{print $1}'`
   fi

   if [ "${G_CODE}" == "1" ]; then
       code=`echo ${result}|awk -F 'G' '{print $1}'`
       code=`echo "${code}*1024"|bc`
   fi


   if [ "${K_CODE}" == "1" ]; then
       code='1'
   fi

    echo ${code%.*}
  ;;

  maxmemory_human)
    result=`RedisStatus $*`

    # 以下分别写入三种条件判断，因为结果唯一，可以这么写，之后再优化
    M_CODE=`echo ${result}|grep -i m |wc -l`
    G_CODE=`echo ${result}|grep -i g |wc -l`
    K_CODE=`echo ${result}|grep -i k |wc -l`

   if [ "${M_CODE}" == "1" ]; then
       code=`echo ${result}|awk -F '.' '{print $1}'`
   fi

   if [ "${G_CODE}" == "1" ]; then
       code=`echo ${result}|awk -F 'G' '{print $1}'`
       code=`echo "${code}*1024"|bc`
   fi


   if [ "${K_CODE}" == "1" ]; then
       code='1'
   fi

    #echo ${result}|grep -i m &>/dev/null
    #if [ $? -eq 0 ]; then
    #    code=`echo ${result}|awk -F"." '{print $1}'`
    #else
    #    code=`echo ${result}|awk -F"G" '{print $1}'`
    #    #echo $code
    #    code=`echo "${code}*1024"|bc`
    #    #code=$((coode*1024))
    #fi
    echo ${code%.*}
  ;;

  connected_clients)
    code=`RedisStatus $*`
    echo ${code}
  ;;

  role)
    result=`RedisStatus $*|awk -F "\r" '{print $1}'`
    #echo "${result}...."
    if [ "${result}" == "master" ]; then
        code='1'
    else
        code='0'
    fi
    echo ${code}
  ;;

  *)
    echo "USAGE: used_memory_human|maxmemory_human|connected_clients|role"
  ;;
esac

