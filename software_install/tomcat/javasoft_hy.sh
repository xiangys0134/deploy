#!/bin/bash
# Yusin 250919938@qq.com
# 2021.4.7
# v1.0.1
# jdk tomcat 安装脚本 注：离线安装则想将jdk-8u152-linux-x64.tar.gz、apache-tomcat-8.0.39.tar.gz下载至/tmp目录

jdk_pag="jdk-8u152-linux-x64.tar.gz"
source_pag="https://shelllinux.oss-cn-shanghai.aliyuncs.com"
cmd=`pwd`

[ -f /etc/profile ] && . /etc/profile
[ $# -ne 1 ] && {
                    echo -e "\033[31;1m 传递参数有误\033[0m"
                    exit 9
                }

function check_rpm {
    rpm_package=$1
    package_num=`rpm -qa |grep ${rpm_package}|wc -l`
    #此类判断VSFTPD可以检测到,其他RPM包检测请慎用
    echo ${package_num}
}

function check_install {
    if [ -f /var/log/jdk.lock ]; then
        echo -e "\033[31;1mJDK已经安装过,请确认\033[0m"
        exit 1
    fi
}

function check_user {
    check_install
    # ping -c 1 -W 1 www.baidu.com &>/dev/null
    # if [ $? -ne 0 ]; then
    #     echo -e "\033[31;1m网络连接失败，请检查\033[0m"
    #     exit 5
    # fi

    # if [ "`echo $UID`" != "0" ]; then
    #     echo -e "\033[31;1m该软件需要root安装权限\033[0m"
    #     exit 4
    # fi
     touch /opt/soft_install.txt &>/dev/null
    if [ $? -ne 0 ]; then
      echo "无法执行权限，请确认该用户权限问题..."
      exit 5
    fi
}

function jdk_install {
    echo "检查jdk...."
    java -version &>/dev/null
    if [ $? -eq 0 ]; then
        java -version
        echo "\n"
        java -version 2>&1|grep -i openjdk &>/dev/null
        if [ $? -eq 0 ]; then
            echo "卸载openjdk中,请稍后...."
             rpm -qa|grep "java-1."|while read pag
            do
               rpm  -e --nodeps ${pag}
            done

            cd ${cmd}
            if [ ! -f $jdk_pag ]; then
                wget ${source_pag}/deploy/source/jdk-8u152-linux-x64.tar.gz &>/dev/null
                if [ $? -ne 0 ]; then
                    echo "download失败,结束jdk自动安装,请手动安装"
                    return 4
                fi
            fi

            tar zxf jdk-8u152-linux-x64.tar.gz
            cd jdk1.8.0_152
             mkdir -p /usr/local/java/jdk1.8.0
             mv ./* /usr/local/java/jdk1.8.0/
             ln -s /usr/local/java/jdk1.8.0 /usr/local/java/jdk
            cd ${cmd}
            # rm -rf jdk1.8.0_152*
            echo "正在配置环境变量"
            echo "
    export JAVA_HOME=/usr/local/java/jdk
    export JRE_HOME=\$JAVA_HOME/jre
    export PATH=\$JAVA_HOME/bin:\$JAVA_HOME/jre/bin:\$PATH
    export CLASSPATH=.:\$JAVA_HOME/lib:\$JAVA_HOME/jre/lib
    " >> /etc/profile &&  touch /var/log/jdk.lock
            return 0

        else
            echo -e "\033[31;1mjdk已经安装，无需再次安装\033[0m"
            return 9
        fi
    else
        echo "未安装jdk软件,即将安装"
        cd ${cmd}
        if [ ! -f $jdk_pag ]; then
            wget ${source_pag}/deploy/source/jdk-8u152-linux-x64.tar.gz &>/dev/null
            if [ $? -ne 0 ]; then
                echo "download失败,结束jdk自动安装,请手动安装"
                return 4
            fi
        fi
        tar zxf jdk-8u152-linux-x64.tar.gz
        cd jdk1.8.0_152
         mkdir -p /usr/local/java/jdk1.8.0
         mv ./* /usr/local/java/jdk1.8.0/
         ln -s /usr/local/java/jdk1.8.0 /usr/local/java/jdk
        cd ${cmd}
        # rm -rf jdk1.8.0_152*
        echo "正在配置环境变量"
        echo "
export JAVA_HOME=/usr/local/java/jdk
export JRE_HOME=\$JAVA_HOME/jre
export PATH=\$JAVA_HOME/bin:\$JAVA_HOME/jre/bin:\$PATH
export CLASSPATH=.:\$JAVA_HOME/lib:\$JAVA_HOME/jre/lib
" >> /etc/profile &&  touch /var/log/jdk.lock
        return 0
    fi
}

function tomcat_install {
    while true
    do
        read -p "配置安装地址[例:/data/tomcat-8010]:" TOMCAT_DIR
        if [ -d ${TOMCAT_DIR} ]; then
          echo "${TOMCAT_DIR}目录存在，如需重新配置请手动删除该目录"
          exit 5
        else
           mkdir ${TOMCAT_DIR} -p &>/dev/null
        fi

        if [ $? -ne 0 ]; then
            echo -e "\033[31;1m目录创建失败,请重新创建\033[0m"
            continue
        else
            echo "${TOMCAT_DIR}创建成功"
            break
        fi
    done

    cd ${cmd}
    if [ ! -f "apache-tomcat-8.0.39.tar.gz" ]; then
        wget ${source_pag}/deploy/source/apache-tomcat-8.0.39.tar.gz
            if [ $? -ne 0 ]; then
                echo "download失败,结束tomcat自动安装,请手动安装"
                return 4
            fi
    fi
    tar zxf apache-tomcat-8.0.39.tar.gz
    cd apache-tomcat-8.0.39
     mv ./* ${TOMCAT_DIR}
    cd ${cmd}
    #rm -rf apache-tomcat-8.0.39*
}


case $1 in
  jdk)
    jdk_install
    ;;
  tomcat)
    tomcat_install
    ;;
  *)
    echo "USAG: $0 {jdk|tomcat}"
    ;;
esac
