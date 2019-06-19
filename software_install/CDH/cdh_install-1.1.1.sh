#!/bin/bash
# CDH一键安装
# Author: yousong.xiang
# Date:  2019.6.18
# Version: v1.0.2
# Example: $0 {master|slave} {master_hostname|master_hostip}

[ -f /etc/profile ] && . /etc/profile
[ -f /etc/init.d/functions ] && . /etc/init.d/functions

[ $# -ne 2 ] && {
                    echo -e "\033[31m传递参数有误\033[0m"
                    echo "USAGE: $0 {master|slave} {master_hostname|master_hostip}"
                    exit 9
                }

cmd=`pwd`
check_file=/var/log/cdh_install.log
VERSION=6.2.0
jdk_num=1.8.0
jdk_version=181
jdk_rpm=https://soft.g6p.cn/deploy/rpm/x86_64/CDH-6.2.0/Cloudera/oracle-j2sdk1.8-${jdk_num}%2Bupdate${jdk_version}-1.x86_64.rpm
cloudera_manager_daemons_rpm=https://soft.g6p.cn/deploy/rpm/x86_64/CDH-6.2.0/Cloudera/cloudera-manager-daemons-6.2.0-968826.el7.x86_64.rpm
cloudera_manager_server_rpm=https://soft.g6p.cn/deploy/rpm/x86_64/CDH-6.2.0/Cloudera/cloudera-manager-server-6.2.0-968826.el7.x86_64.rpm
cloudera_manager_agent_rpm=https://soft.g6p.cn/deploy/rpm/x86_64/CDH-6.2.0/Cloudera/cloudera-manager-agent-6.2.0-968826.el7.x86_64.rpm
manifest_json=https://soft.g6p.cn/deploy/rpm/x86_64/CDH-6.2.0/Parcels/manifest.json
parcel_sha256=https://soft.g6p.cn/deploy/rpm/x86_64/CDH-6.2.0/Parcels/CDH-6.2.0-1.cdh6.2.0.p0.967373-el7.parcel.sha256
parcel=https://soft.g6p.cn/deploy/rpm/x86_64/CDH-6.2.0/Parcels/CDH-6.2.0-1.cdh6.2.0.p0.967373-el7.parcel
mysql_connector_java_pkg=https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.46.tar.gz
mysql_connector_java_version=5.1.46
host_name=$2

function maue() {
cat << EOF
1.JDK: ${jdk_rpm##*/}
2.cloudera-manager-daemons: ${cloudera_manager_daemons_rpm##*/}
3.cloudera-manager-server: ${cloudera_manager_server_rpm##*/}
4.cloudera-manager-agent: ${cloudera_manager_agent_rpm##*/}
5.manifest.json: ${manifest_json##*/}
6.CDH: ${parcel##*/}
7.mysql-connector-java: ${mysql_connector_java_pkg##*/}
8.mysql: mysql-community-server-5.6
EOF
    echo "软件版本信息"
}

function Complete() {
    echo "安装完毕,请检查安装日志信息"
}


function env_check() {
    uid=$(id -u)
    if [ ${uid} -ne 0 ]; then
        echo '==此脚本需要root用户执行,程序即将退出.'
        exit 2        
    fi

    ping -c 4 -W 5 www.aliyun.com >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo '网络不通,请检查网络'
        exit 6
    fi 
}

function check_rpm(){
    rpm_name=$1
    num=`rpm -qa|grep ${rpm_name}|wc -l`
    echo ${num}
}


remi_install() {
    #关闭selinux
    sed  -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0

    if [ "`check_rpm redhat-lsb-core`" == "0" ]; then
        yum install -y redhat-lsb-core >/dev/null 2>&1
        if [ "`check_rpm redhat-lsb-core`" != "0" ]; then
            echo "\033[31m安装redhat-lsb-core成功\033[0m"
        else
            echo "\033[31m安装redhat-lsb-core失败\033[0m"
        fi
    fi
}

#修改文件句柄
function set_limit() {
  max_files="##
* soft nofile 655350
* hard nofile 655350
"

    soft_limit=$(grep 'soft nofile' /etc/security/limits.conf |wc -l)
    soft_limit=$(grep 'hard nofile' /etc/security/limits.conf |wc -l)
    if [ "${soft_limit}" == "0"  -a "${soft_limit}" == "0" ]; then
        echo "${max_files}" >> /etc/security/limits.conf
        echo "文件句柄设置完成"
    else
        echo "文件句柄设置已设置"
    fi
}

function GO_READY() {
    #配置swap内存使用规则
    swapvm_num=`sed -n '/vm.swappiness[[:space:]]*=/p' /etc/sysctl.conf|wc -l`
    if [ ${swapvm_num} -ge 1 ]; then
        sed -i '/vm.swappiness[[:space:]]*=/cvm.swappiness = 0' /etc/sysctl.conf
    else
        echo vm.swappiness = 0 >> /etc/sysctl.conf
    fi
    sysctl -p &>/dev/null

    #所有节点大页面禁用
    if [ ! -f /var/log/transparent_hugepage_defrag ]; then
        echo never>/sys/kernel/mm/transparent_hugepage/defrag && \
        echo "echo never>/sys/kernel/mm/transparent_hugepage/defrag" >> /etc/rc.local && \
        chmod +x /etc/rc.d/rc.local && \
        touch /var/log/transparent_hugepage_defrag       
    fi

    if [ ! -f /var/log/transparent_hugepage_enabled ]; then
        echo never>/sys/kernel/mm/transparent_hugepage/enabled && \
        echo "echo never>/sys/kernel/mm/transparent_hugepage/enabled" >> /etc/rc.local && \
        chmod +x /etc/rc.d/rc.local && \
        touch /var/log/transparent_hugepage_enabled
    fi

}

function mysql_install() {
    #未将MYSQL安装脚本集成至此脚本中
    [ -f mysql-xunce-5.6.sh ] && rm -rf mysql-xunce-5.6.sh
    wget https://raw.githubusercontent.com/xiangys0134/deploy/master/software_install/mysql/mysql-xunce-5.6.sh && bash mysql-xunce-5.6.sh db
}

function Cloudera_master_install() {
    master_hostname=$1
    #安装Cloudera Manager

    [ ! -d /tmp/master_pkg ] && mkdir /tmp/master_pkg -p || rm -rf /tmp/master_pkg/*
    cd /tmp/master_pkg

    wget ${jdk_rpm}
    yum localinstall -y *.rpm
    JAVA_HOME=/usr/java/jdk${jdk_num}_${jdk_version}-cloudera
    PATH=$PATH:$JAVA_HOME/bin
    wget ${cloudera_manager_daemons_rpm} && \
    wget ${cloudera_manager_server_rpm} && \
    wget ${cloudera_manager_agent_rpm} || echo "download Cloudera rpm pkg failed"
    
    yum localinstall -y *.rpm

    echo "export JAVA_HOME=/usr/java/jdk${jdk_num}_${jdk_version}-cloudera" >> /etc/profile && \
    echo "export PATH=\$PATH:\$JAVA_HOME/bin" >> /etc/profile && \
    source /etc/profile


    if [ -f /etc/cloudera-scm-agent/config.ini ]; then
        sed -i "/^server_host=/c\server_host=${master_hostname}" /etc/cloudera-scm-agent/config.ini
    else
        echo "cloudera-scm-agent install error!"
    fi
}


function Cloudera_slave_install() {
    master_hostname=$1
    if [ `check_rpm wget` -lt 1 ]; then
        yum install -y wget &>/dev/null
    fi
    [ ! -d /tmp/slave_pkg ] && mkdir /tmp/slave_pkg -p || rm -rf /tmp/slave_pkg/*
    cd /tmp/slave_pkg

    wget ${jdk_rpm}
    yum localinstall -y *.rpm
    JAVA_HOME=/usr/java/jdk${jdk_num}_${jdk_version}-cloudera
    PATH=$PATH:$JAVA_HOME/bin
    wget ${cloudera_manager_daemons_rpm} && \
    wget ${cloudera_manager_agent_rpm} || echo "download Cloudera rpm pkg failed"
    
    yum localinstall -y *.rpm
 
    echo "export JAVA_HOME=/usr/java/jdk${jdk_num}_${jdk_version}-cloudera" >> /etc/profile && \
    echo "export PATH=\$PATH:\$JAVA_HOME/bin" >> /etc/profile && \
    source /etc/profile

    if [ -f /etc/cloudera-scm-agent/config.ini ]; then
        sed -i "/^server_host=/c\server_host=${master_hostname}" /etc/cloudera-scm-agent/config.ini
    else
        echo "cloudera-scm-agent install error!"
    fi
}

function CDH_Cluster_install() {
    #CDH cluster
    if [ ! -d /opt/cloudera/parcel-repo ]; then
        mkdir /opt/cloudera/parcel-repo -p
    fi
    JAVA_HOME=/usr/java/jdk${jdk_num}_${jdk_version}-cloudera
    PATH=$PATH:$JAVA_HOME/bin 
    cd /opt/cloudera/parcel-repo
    wget ${manifest_json} &>/dev/null && echo "download manifest.json seccess" || echo "download manifest.json failed"
    wget ${parcel_sha256} &>/dev/null && echo "download parcel_sha256 seccess" || echo "download parcel_sha256 failed"
    wget ${parcel} &>/dev/null && echo "download parcel seccess" || echo "download parcel failed"
    find ./ -name "CDH-${VERSION}-*-el7.parcel.sha256"|cut -d "/" -f 2 |head -1|while read file
    do
        pkg=${file%256}
        echo "mv ${file} ${pkg}"
        mv ${file} ${pkg}
    done
    cd ${cmd}
}

function mysql_connector_java() {
    [ -d /tmp/tmp_mysql_connector_java_pkg ] && rm -rf /tmp/tmp_mysql_connector_java_pkg
    [ ! -d /usr/share/java ] && mkdir /usr/share/java -p
    mkdir /tmp/tmp_mysql_connector_java_pkg -p && cd /tmp/tmp_mysql_connector_java_pkg
    wget ${mysql_connector_java_pkg} &>/dev/null && echo "download mysql_connector_java seccess" || echo "download mysql_connector_java failed"
    find ./ -name "*.tar.gz" |cut -d "/" -f 2|head -1|while read file
    do
        tar -zxf ${file}
        echo "/bin/cp -rf mysql-connector-java*/mysql-connector-java-[0-9]*.[0-9]*.[0-9]*-bin.jar /usr/share/java/mysql-connector-java.jar"
        /bin/cp -rf mysql-connector-java*/mysql-connector-java-[0-9]*.[0-9]*.[0-9]*-bin.jar /usr/share/java/mysql-connector-java.jar
        if [ $? -ne 0 ]; then
            echo -e "\033[31;1m mysql-connector-java.jar copy failed!!! \033[0m"
        fi
    done
}

function firewall_cmd() {
    firewall-cmd --list-all &>/dev/null
    if [ $? -eq 0 ]; then
        firewall-cmd --zone=public --add-port=7180/tcp --permanent &>/dev/null
        firewall-cmd --zone=public --add-port=8088/tcp --permanent &>/dev/null
        firewall-cmd --zone=public --add-port=19888/tcp --permanent &>/dev/null
        firewall-cmd --zone=public --add-port=18088/tcp --permanent &>/dev/null
        firewall-cmd --zone=public --add-port=10002/tcp --permanent &>/dev/null
        firewall-cmd --zone=public --add-port=8020/tcp --permanent &>/dev/null
        firewall-cmd --zone=public --add-port=50070/tcp --permanent &>/dev/null
        firewall-cmd --zone=public --add-port=60010/tcp --permanent &>/dev/null
        firewall-cmd --zone=public --add-port=8888/tcp --permanent &>/dev/null
        firewall-cmd --zone=public --add-port=8889/tcp --permanent &>/dev/null
        firewall-cmd --zone=public --add-port=9092/tcp --permanent &>/dev/null
        firewall-cmd --zone=public --add-port=11000/tcp --permanent &>/dev/null
        firewall-cmd --reload &>/dev/null
    fi
}

case "$1" in
  master)
    env_check
    maue
    remi_install
    set_limit
    GO_READY
    mysql_install
    Cloudera_master_install ${host_name}
    CDH_Cluster_install
    mysql_connector_java
    firewall_cmd
    Complete
  ;;
  slave)
    env_check
    maue
    remi_install
    set_limit
    GO_READ
    Cloudera_slave_install ${host_name}
    mysql_connector_java
    firewall_cmd
    Complete
  ;;
  *)
    echo "USAGE: $0 {master|slave} {master_hostname|master_hostip}"
esac
