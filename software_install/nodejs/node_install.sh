#!/bin/bash
# Nodejs0.8安装
# Author: yousong.xiang
# Date:  2018.11.27
# Version: v1.0.2

[ -f /etc/profile ] && . /etc/profile


version=10

function check_rpm() {
    rpm_name=$1
    num=`rpm -qa|grep ${rpm_name}|wc -l`
    echo ${num}
}

function epel_install() {
    #关闭selinux,安装基础依赖环境函数
    sed -i '/^SELINUX=.*/s/SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux
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
    echo ${sys_ver}    

    #判断是否安装remi-release,如果没有安装则安装
    if [ `check_rpm remi-release` == '0' ]; then
        rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-${sys_ver}.rpm  &>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "\033[32;1mepel-release install seccuess\033[0m"
            yum clean all            
        else
            echo -e "\033[31;1mepel-release install fail\033[0m"
        fi
    fi   

    if [ `check_rpm wget` == '0' ]; then
        yum install -y wget
    fi
}

function nodejs_install() {
        yum install -y gcc-c++ make
        curl --silent --location https://rpm.nodesource.com/setup_${version}.x | bash -
        yum install -y nodejs  
        curl -sL https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo >/dev/null >&1
        yum install -y yarn
        npm install -g cnpm --registry=https://registry.npm.taobao.org
        cnpm install pm2 -g

        if [ `check_rpm nodejs` != '0' ]; then
            echo -e '\033[32m nodejs install success\033\0m'
        else
            echo -e '\033[31m nodejs install fail\033[0m'
        fi

}


epel_install
nodejs_install

