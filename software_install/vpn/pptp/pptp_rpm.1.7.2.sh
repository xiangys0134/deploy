#!/bin/bash
# yousong.xiang 250919938@qq.com
# 2019.3.7
# v1.0.1
# pptpd rpm包安装脚本

[ -f /etc/profile ] && . /etc/profile
cmd=`dirname $0`
if [ "${cmd}" == '.' ]; then
    cmd=`pwd`
fi

#检查网络状态
function env_check() {
    uid=$(id -u)
    if [ ${uid} -ne 0 ]; then
        echo '==此脚本需要root用户执行,程序即将退出.'
        exit 2        
    fi

    ping -c 1 -W 2 www.baidu.com >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo '==网络不通,请检查网络'
        exit 6
    fi 
}


#检查rpm包是否安装
function check_rpm() {
    rpm_pkg=$1
    num=`rpm -qa|grep ${rpm_pkg}|wc -l`
    echo ${num}
}


function epel_install() {
    #关闭selinux,安装基础依赖环境函数
    sed -i '/^SELINUX=enforcing$/s/SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux
    setenforce 0
    #判断是否安装redhat-lsb-core
    if [ `check_rpm redhat-lsb-core` == '0' ]; then
        yum install -y redhat-lsb-core  >/dev/null >&1
    fi 

    if [ `check_rpm epel-release` == '0' ]; then
        yum install -y epel-release
    fi

    #重新加载环境变量 
    sys_ver=`lsb_release -r |awk -F' ' '{print $2}'|awk -F'.' '{ print $1 }'`
    #echo ${sys_ver}    

    #判断是否安装remi-release,如果没有安装则安装
    if [ `check_rpm remi-release` == '0' ]; then
        rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-${sys_ver}.rpm  &>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "\033[32;1mremi-release install seccuess\033[0m" |tee -a ${log}
            yum clean all            
        else
            echo -e "\033[31;1mremi-release install fail\033[0m" |tee -a ${log}
        fi
    fi   

    if [ `check_rpm wget` == '0' ]; then
        yum install -y wget
    fi

}

#关闭selinux
function selinux_stop(){
    sed -i '/^SELINUX=enforcing$/c\SELINUX=disabled' /etc/selinux/config
    setenforce 0
}

#net.ipv4.ip_forward
function forward() {
    grep "net.ipv4.ip_forward[[:space:]]\{0,\}=" /etc/sysctl.conf &>/dev/null
    sed -i '/net.ipv4.ip_forward[[:space:]]\{0,\}=/c\net.ipv4.ip_forward = 1' /etc/sysctl.conf
    sysctl -p &>/dev/null
}

function pptp_config() {
    env_check
    selinux_stop
    epel_install
    yum install -y net-tools iptables-services ppp pptpd
    if [ $? -ne 0 ]; then
        echo -e "\033[31myum pptpd faild\033[0m"
        exit 7
    fi
  
    if [ ! -f /etc/pptpd.conf ]; then
        echo -e "\033[31mpptpd.conf not exist\033[0m"
        exit 8
    fi
    echo "ppp /usr/sbin/pppd" >> /etc/pptpd.conf
    echo "以下如果填写错误，则在安装完成后修改/etc/pptpd.conf[例:localip IP地址]"
    read -p "请输入虚拟网关地址[默认eth0网卡地址]：" localip
    localip=${localip:-"127.0.0.1"}

    echo "localip ${localip}" >> /etc/pptpd.conf
    echo "remoteip 10.18.5.3-238,10.18.5.1" >> /etc/pptpd.conf     
    
    if [ ! -f /etc/ppp/options.pptpd ]; then
        echo -e "\033[31moptions.pptpd not exist\033[0m"
        exit 9
    else
        echo "ms-dns 114.114.114.114" >> /etc/ppp/options.pptpd
    fi
    
    pptp_user=admin
    pptp_pass=`echo $RANDOM|md5sum |cut -c 2-10`

    read -p "新建PPTP用户名[回车默认用户为admin]：" user
    read -p "创建PPTP密码[回车动态生成密码${pptp_pass}]：" pass

    user=${user:-${pptp_user}}
    pass=${pass:-${pptp_pass}}
   
    if [ ! -f /etc/ppp/chap-secrets ]; then
        echo -e "\033[31mchap-secrets not exist\033[0m"
        exit 1
    else
        echo "${user} pptpd ${pass} *" >> /etc/ppp/chap-secrets
    fi
   
    echo -e "\033[32;1PPTP用户名：${user}\033[0m"    
    echo -e "\033[32;1PPTP密码：${pass}\033[0m"    

}


function pptp_service() {
    systemctl start pptpd.service &>/dev/null
    systemctl enable pptpd.service &>/dev/null
    #开启内核转发模式
    forward
}

function firewall_cmd() {
    firewall-cmd --list-all &>/dev/null
    if [ $? -eq 0 ]; then
        ETH=`ifconfig|egrep -o "^(e[tn][hs][0-9]+)"`
        echo "fireall-cmd setup start"
        #firewall-cmd --permanent --zone=public --add-service=pptpd 
        firewall-cmd --add-masquerade 
        firewall-cmd --permanent --zone=public --add-port=47/tcp 
        firewall-cmd --permanent --zone=public --add-port=1723/tcp --permanent 
        firewall-cmd --permanent --zone=public --add-port=443/tcp --permanent 

        firewall-cmd --permanent --direct --add-rule ipv4 filter INPUT 0 -p gre -j ACCEPT 
        firewall-cmd --permanent --direct --add-rule ipv4 filter OUTPUT 0 -p gre -j ACCEPT 

        #设置规则允许数据包由ens32和ppp+接口中进出
        #firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -i ppp+ -o ${ETH}-j ACCEPT &>/dev/null
        firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -i ppp+ -o ${ETH} -j ACCEPT 
        firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -i ${ETH} -o ppp+ -j ACCEPT

        #设置转发规则，从源地址发出的所有包都进行伪装，改变地址，由ens32发出
        firewall-cmd --permanent --direct --passthrough ipv4 -t nat -I POSTROUTING -o ${ETH} -j MASQUERADE -s 10.18.5.0/24 &>/dev/null

        firewall-cmd --reload &>/dev/null
        echo "fireall-cmd setup end"
        firewall-cmd --list-all
    fi
}


pptp_config
pptp_service
firewall_cmd
