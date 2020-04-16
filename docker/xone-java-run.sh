#!/bin/bash
# docker-compose容器管理
# Author yousong.xiang yousong.xiang@tech.com
# Date 2020.4.16
# v1.0.1

server_app="
xone-registration
xone-configuration
xone-authorization
xone-foundation
xone-instruction
xone-workflow
xone-attachment
xone-gateway
"
docker_compose='/usr/local/bin/docker-compose'
docker_compose_file='/data/xunce/compose/docker-compose.yml'
#关键字过滤示例 grep zhaoshangxone |grep XONE-
xone_java_image='zhaoshangxone,XONE-'


[ $# -ne 1 ] && {
                    echo "\033[31m 传递参数有误 \033[0m"
                    exit 9
                }


#停止容器
function get_docker_id {
  docker_server=$1
  docker_count=`sudo ${docker_compose} -f ${docker_compose_file} ps|grep ${docker_server}|wc -l`
  if [ ${docker_count} -eq 1 ]; then
    sudo ${docker_compose} -f ${docker_compose_file} stop ${docker_server}
    [ $? -ne 0 ] && return 3
    sudo ${docker_compose} -f ${docker_compose_file} rm -f ${docker_server}
    if [ $? -eq 0 ]; then 
      return 0
    else
      return 3
    fi
  elif [  ${docker_count} -gt 1 ]; then
    sudo ${docker_compose} -f ${docker_compose_file} stop ${docker_server}
    [ $? -ne 0 ] && return 3
    sudo ${docker_compose} -f ${docker_compose_file} rm -f ${docker_server}
    if [ $? -eq 0 ]; then 
      return 1
    else
      return 3
    fi
  else
    return 2
  fi
}

#删除docker镜像
function drop_docker_image {
  #$1为传递进来的image关机子匹配 例如'aaa,bbb' 表示先grep匹配aaa关键字，再匹配bbb关键字
  str_grep=$1
  # re_str=`echo $str_grep|awk -F ',' '{for(count=1;count<=NF;count++)printf "grep $count"'|'}'`
  # echo $str_grep
  # echo "echo $str_grep|awk -F ',' '{for(count=1;count<=NF;count++)printf "grep "$count"|"}'"
  re_str=`echo $str_grep|awk -F ',' '{for(count=1;count<=NF;count++)printf "grep "$count"|"}'`
  if [ -n "${re_str}" ]; then
    re_str=${re_str%%|}
    cmd="sudo /bin/docker images| $re_str"
    docker_image_id=`eval $cmd|awk '{print $3}'`
    sudo /bin/docker rmi ${docker_image_id}
    if [ $? -eq 0 ]; then
      return 0
    else
      return 1
    fi
  fi
}

#启动新版本容器
function start_docker {
  docker_server=$1
  sudo ${docker_compose} -f ${docker_compose_file} up -d ${docker_server}
  if [ $? -eq 0 ]; then
    return 0
  else
    return 1
  fi
}

#3个步骤处理以下操作
#1.停止容器，删除容器
#2.删除镜像
#3.run新版本的容器

case "$1" in
  up)
    for app in $server_app
    do
      #停止容器
      get_docker_id $app 
      if [ $? -eq 0 ]; then
        echo -e "\033[32m docker app stop: ${app} 成功 \033[0m"
      elif [ $? -eq 1 ]; then
        echo -e "\033[32m docker app stop: ${app} 成功 \033[0m"
        echo -e "存在多个名称：${app} 的容器"
      else
        echo -e "\033[31m docker app stop: ${app} 失败 \033[0m"
      fi
    done
    
    #删除镜像 通过传递关键字进行匹配docker image
    drop_docker_image ${xone_java_image}
    if [ $? -eq 0 ]; then
      echo -e "\033[32m docker image rm : 成功 \033[0m"
    else
      echo -e "\033[31m docker image rm : 失败 \033[0m"
    fi
    
    #run容器
    for app in $server_app
    do
      start_docker $app 
      if [ $? -eq 0 ]; then
        echo -e "\033[32m docker server: ${docker_server} 启动成功 \033[0m"
      else
        echo -e "\033[31m docker server: ${docker_server} 启动失败 \033[0m"
      fi
    done
    ;;
  down)
    for app in $server_app
    do
      #停止容器
      get_docker_id $app 
      if [ $? -eq 0 ]; then
        echo -e "\033[32m docker app stop: ${app} 成功 \033[0m"
      elif [ $? -eq 1 ]; then
        echo -e "\033[32m docker app stop: ${app} 成功 \033[0m"
        echo -e "存在多个名称：${app} 的容器"
      else
        echo -e "\033[31m docker app stop: ${app} 失败 \033[0m"
      fi
    done
    ;;
  *)
    echo "USAGE:{up|down}"
    ;;
esac


