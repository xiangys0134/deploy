#!/bin/bash
#yousong.xiang 2018.10.3
#RPM安装elk
#v1.0.1
[ -f /etc/init.d/functions ] && . /etc/init.d/functions
[ -f /etc/profile ] && . /etc/profile

currentpath=`pwd` #当前路径
conf=user.conf   # 配置文件
modpath=include  # 模块文件
jdk_version="java-1.8.0-openjdk"
es_data=/data/es-data
es_logs=/var/log/elasticsearch
url='http://soft.g6p.cn/deploy/source'
es_rpm=elasticsearch-5.0.1.rpm
logstash_rpm=logstash-5.0.1.rpm
kibana_rpm=kibana-5.0.1-x86_64.rpm

check_rpm() {
    rpm_nodes=$1
    rpm_wc=`rpm -qa|grep ${rpm_nodes}|wc -l`
    echo ${rpm_wc}
}

init(){ 
  echo -e "\033[32;1m安装依赖软件包，请稍等...\033[0m"
  yum install make cmake gcc gcc-c++ -y
  for packages in make cmake gcc gcc-c++ gcc-g77 flex bison file libtool \
    libtool-libs autoconf kernel-devel patch wget libjpeg libjpeg-devel libpng \
    libpng-devel libpng10 libpng10-devel gd gd-devel libxml2 libxml2-devel zlib \
    zlib-devel glib2 glib2-devel unzip tar bzip2 bzip2-devel libevent libevent-devel \
    ncurses ncurses-devel curl curl-devel libcurl libcurl-devel e2fsprogs e2fsprogs-devel \
    krb5 krb5-devel libidn libidn-devel openssl openssl-devel vim-minimal gettext gettext-devel \
    ncurses-devel gmp-devel pspell-devel unzip libcap diffutils ca-certificates net-tools libc-client-devel \
    psmisc libXpm-devel git-core c-ares-devel libicu-devel libxslt libxslt-devel pcre-devel \
    pcre luajit lua luajit-devel libmcrypt-devel libmcrypt mcrypt mhash-devel tcl;do 
    yum -y install $packages; 
  done
  echo -e "\033[32;1m安装依赖软件包成功...\033[0m"
}

installjdk() {
  if [ "`check_rpm ${jdk_version}`" == "0" ]; then
      echo -e "\033[32;1m安装jdk，请稍等...\033[0m"
      cd ${currentpath}
      yum install ${jdk_version} -y
      echo -e "\033[32;1mjdk1.8安装成功...\033[0m"
  else
      echo -e "\033[31;1m已安装过jdk1.8,请检查\033[0m"
      read -p "请确认是否安装jdk[y|n]" repeat
      if [ "$repeat" == "y" -o "$repeat" == "Y" ];then
          yum install ${jdk_version} -y
      elif [ "$repeat" == "n" -o "$repeat" == "N" ];then
          echo -e "\033[31;1m即将跳转至安装页面\033[0m"
      else
          echo -e "\033[31;1m错误选项,即将跳转至安装页面\033[0m"    
      fi
  fi
}

es_file() {
  es_file=/etc/elasticsearch/elasticsearch.yml
  [ -f ${es_file} ] && mv ${es_file} ${es_file}bak
  cat >>${es_file}<< EOF
cluster.name: my-application
node.name: node-1
path.data: ${es_data}
path.logs: ${es_logs}
network.host: 0.0.0.0
http.port: 9200
http.cors.enabled: true
http.cors.allow-origin: "*"
EOF
}


esinstall() {
  if [ "`check_rpm elasticsearch`" == "0" ]; then
      cd ${currentpath}
      [ ! -f ${es_rpm} ] && wget ${url}/${es_rpm}
      if [ $? -eq 0 ]; then
          rpm -ivh ${es_rpm}
          [ $? -eq 0 ] && es_file || echo -e "\033[31;1m安装失败!\033[0m"
      else
          echo "\033[31;1mDownload ${es_rpm} false...\033[0m"
      fi
  else
      echo -e "\033[31;1m已安装过${es_rpm},请检查\033[0m"
      read -p "请确认是否安装${es_rpm}[y|n]" repeat
      if [ "$repeat" == "y" -o "$repeat" == "Y" ];then
          cd ${currentpath}
          [ ! -f ${es_rpm} ] && wget ${url}/${es_rpm}
          rpm -ivh ${es_rpm}
          [ $? -eq 0 ] && es_file ||  echo -e "\033[31;1m安装失败!\033[0m"
      elif [ "$repeat" == "n" -o "$repeat" == "N" ];then
          echo -e "\033[31;1m即将跳转至安装页面\033[0m"
      else
          echo -e "\033[31;1m错误选项,即将跳转至安装页面\033[0m"     
      fi
      
  fi



}



logstashinstall() {
  if [ "`check_rpm logstash`" == "0" ]; then
      cd ${currentpath}
      [ ! -f ${logstash_rpm} ] && wget ${url}/${logstash_rpm}
      if [ $? -eq 0 ]; then
          rpm -ivh ${logstash_rpm}
      else
          echo "\033[31;1mDownload ${logstash_rpm} false...\033[0m"
      fi
  else
      echo -e "\033[31;1m已安装过${logstash_rpm},请检查\033[0m"
      read -p "请确认是否安装${logstash_rpm}[y|n]" repeat
      if [ "$repeat" == "y" -o "$repeat" == "Y" ];then
          cd ${currentpath}
          [ ! -f ${logstash_rpm} ] && wget ${url}/${logstash_rpm}
          rpm -ivh ${logstash_rpm}
          [ $? -eq 0 ] && echo -e "\033[32;1m安装成功!\033[0m" || echo -e "\033[31;1m安装失败!\033[0m" 
      elif [ "$repeat" == "n" -o "$repeat" == "N" ];then
          echo -e "\033[31;1m即将跳转至安装页面\033[0m"
      else
          echo -e "\033[31;1m错误选项,即将跳转至安装页面\033[0m"
      fi
   
  fi
}



kibanainstall() {
    if [ "`check_rpm kibana`" == "0" ]; then
        cd ${currentpath}
        [ ! -f ${kibana_rpm} ] && wget ${url}/${kibana_rpm}
        if [ $? -eq 0 ]; then
            rpm -ivh ${kibana_rpm}
        else
            echo "\033[31;1mDownload ${kibana_rpm} false...\033[0m"    
        fi
    else
        echo -e "\033[31;1m已安装过${kibana_rpm},请检查\033[0m"
        read -p "请确认是否安装${kibana_rpm}[y|n]" repeat
        if [ "$repeat" == "y" -o "$repeat" == "Y" ];then
            cd ${currentpath}
            [ ! -f ${kibana_rpm} ] && wget ${url}/${kibana_rpm}
            rpm -ivh ${kibana_rpm}
            [ $? -eq 0 ] && echo -e "\033[32;1m安装成功!\033[0m" || echo -e "\033[31;1m安装失败!\033[0m"
        elif [ "$repeat" == "n" -o "$repeat" == "N" ];then
            echo -e "\033[31;1m即将跳转至安装页面\033[0m"
        else
            echo -e "\033[31;1m错误选项,即将跳转至安装页面\033[0m"     
      fi
    
    fi

}


# 主菜单
main_menu(){
  echo -e "\033[35;1m##############################\033[0m"
  echo -en "\033[35;1m#  1."
  printf "%-26s" 安装jdk
  echo -e "#\033[0m"
  echo -en "\033[35;1m#  2."
  printf "%-26s" 安装elasticsearch
  echo -e "#\033[0m"
  echo -en "\033[35;1m#  3."
  printf "%-26s" 安装logstash 
  echo -e "#\033[0m"
  echo -en "\033[35;1m#  4."
  printf "%-26s" 安装kibana   
  echo -e "#\033[0m"
  echo -en "\033[35;1m#  0."
  printf "%-26s" "退出"
  echo -e "#\033[0m"
  echo -e "\033[35;1m##############################\033[0m"
}

# 主菜单功能
main_select(){
  clear 
  while [ 1 ];do
    main_menu
    read -p "请选择需要的功能：" main_seq
    case ${main_seq} in
      1)   
        installjdk
        ;;
      2)
        esinstall 
        ;;
      3)
        logstashinstall
        ;;
      4)
        kibanainstall
        ;;
      0)
        break
        ;;
      *)
        echo -e "\033[31;1m输入错误,请重新输入。\033[0m"
        ;;
    esac
  done
}

main() {
  if [ $UID -ne 0 ];then
    echo "当前用户不是root,请使用root帐户运行程序!"
    exit 1
  fi
  init
  main_select
}

main $*



