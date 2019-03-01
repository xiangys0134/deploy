#!/bin/bash
# yousong.xiang 250919938@qq.com
# 2019.3.1
# v1.0.1
# jdk tomcat 安装脚本

[ -f /etc/profile ] && . /etc/profile

cmd=`dirname $0`



function check_rpm() {
    rpm_package=$1
    package_num=`rpm -qa |grep ${rpm_package}|wc -l`
    #此类判断VSFTPD可以检测到,其他RPM包检测请慎用
    echo ${package_num}
}

function check_install() {
    if [ -f /var/log/jdk.lock ]; then
        echo -e "\033[31;1mJDK已经安装过,请确认\033[0m"
        exit 1
    fi
}

function check_ping() {
    check_install
    ping -c 1 -W 1 www.baidu.com &>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "\033[31;1m网络连接失败，请检查\033[0m"
        exit 5
    fi

    if [ "`echo $UID`" != "0" ]; then
        echo -e "\033[31;1m该软件需要root安装权限\033[0m"
        exit 4
    fi
}


function jdk_install(){
    echo "检查jdk...."
    java -version &>/dev/null
    if [ $? -eq 0 ]; then
        java -version
        echo "\n"
        java -version 2>&1|grep -i openjdk &>/dev/null
        if [ $? -eq 0 ]; then
            echo "卸载openjdk中,请稍后...."
            rpm -qa|grep “java-1.”|while read pag
            do
               rpm  -e --nodeps ${pag}
            done

            cd ${cmd}
            if [ ! -f "jdk-8u152-linux-x64.tar.gz" ]; then
            
                wget http://soft.g6p.cn/deploy/source/jdk-8u152-linux-x64.tar.gz &>/dev/null
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
            cd ${cmd} && rm -rf jdk1.8.0_152*
            return 0

        else
            echo -e "\033[31;1mjdk已经安装，无需再次安装\033[0m"
            return 9
        fi
    else
        echo "未安装jdk软件,即将安装"
        cd ${cmd}
        if [ ! -f "jdk-8u152-linux-x64.tar.gz" ]; then
            wget http://soft.g6p.cn/deploy/source/jdk-8u152-linux-x64.tar.gz &>/dev/null
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
        cd ${cmd} && rm -rf jdk1.8.0_152*
        return 0
    fi   
    
}


function tomcat_install() {
    while true
    do
        read -p "配置安装地址[例:/data/tomcat-8010]:" TOMCAT_DIR
        mkdir ${TOMCAT_DIR} -p &>/dev/null
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
        wget http://soft.g6p.cn/deploy/source/apache-tomcat-8.0.39.tar.gz 
            if [ $? -ne 0 ]; then
                echo "download失败,结束tomcat自动安装,请手动安装"
                return 4
            fi
    fi
    tar zxf apache-tomcat-8.0.39.tar.gz
    cd apache-tomcat-8.0.39
    mv ./* ${TOMCAT_DIR}
    cd ${cmd} && rm -rf apache-tomcat-8.0.39*


}


function config() {
    tomcat_install
    jdk_install
    if [ $? -eq 0 ]; then
        echo "正在配置环境变量"
        echo "
export JAVA_HOME=/usr/local/java/jdk
export JRE_HOME=\$JAVA_HOME/jre
export PATH=\$JAVA_HOME/bin:\$JAVA_HOME/jre/bin:\$PATH
export CLASSPATH=.:\$JAVA_HOME/lib:\$JAVA_HOME/jre/lib
" >> /etc/profile && touch /var/log/jdk.lock && echo echo -e "\033[32;1mjdk1.8安装成功,请执行命令source /etc/profile刷新环境变量\033[0m"     
    fi
}

check_ping
config
