#!/bin/bash
#Nodejs0.8安装
#Author: yousong.xiang
#Date:  2018.11.27
#Version: v1.0.1

[ -f /etc/profile ] && . /etc/profile

if [ $# -ne 1 ]; then
    echo -e "\033[31m传递参数有误\033[0m"
    exit 9
fi

cmd=`dirname $0`
log="./upgrade.log"
exec 2>>${log}

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
    nodejs_repo=/etc/yum.repos.d/nodesource-el7.repo
    nodejs_gpg_key=/etc/pki/rpm-gpg/NODESOURCE-GPG-SIGNING-KEY-EL

    if [ `check_rpm nodejs` == '0' ]; then
        #添加nodejs yum源
        if [ ! -f ${nodejs_repo} ]; then
            cat >>${nodejs_repo}<< EOF
[nodesource]
name=Node.js Packages for Enterprise Linux 7 - $basearch
baseurl=https://rpm.nodesource.com/pub_8.x/el/7/$basearch
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/NODESOURCE-GPG-SIGNING-KEY-EL

[nodesource-source]
name=Node.js for Enterprise Linux 7 - $basearch - Source
baseurl=https://rpm.nodesource.com/pub_8.x/el/7/SRPMS
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/NODESOURCE-GPG-SIGNING-KEY-EL
gpgcheck=1
EOF
        fi

        if [ ! -f ${nodejs_gpg_key} ]; then
            cat >>${nodejs_gpg_key}<< EOF
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1

mQINBFQCN9QBEADv5QYOlCWNkI/oKST/GGpQkOZjFY2cbYdHuc2j8kyM4oeNluXq
puEYMHOoQvbJ3DFPvsv+jCruL7qjkel9YzaF6e3RN2ystP4YBjxyOT7Bb5EnjNNU
6oScQJ50/+RmA4N3wzBrw5+x5KQGBfRU/k7JdDKO6SGY0zzdAo3jqp1nQ9Sf+Fmg
hsjDLVZTHorLPV3yPLb37QlvBB2YIRF+dL9l4wPAI/fGyWv+Qs7VlCZTyRAnKGbv
qN1LvlYoV9YqxaJYYJW+MQhn4706yNJAFeOZuKejEcnZTd/NBiAR91sVnsXKgW9e
yb4TZ7SqkmrJpuKJBpdPr1dgaK8dDmFh9Nlhpz6xZuYcKaDEDa5b3wymnixtwZf2
WyboChIlsHDajtXZt34xP9uUge1VHyk1o8AQUzKEpuepxxLnyXArLgvHaLhQnxPA
bQB43b4RbWYHPdB16ki2WoZX/DA4YEtfxg8GC3zXC2thMJnFburmts71iiYsxKBc
6d7O8415xrErhk2/o2+bRhf+7qBQfW0oxQSEMBYbqP3hvhG1VWc9umjbCfMgHrHo
IzI7W+GbRdbSsdpY6JNKuCftVfIKXeXk5FbUUP9NzsG/nyGFORkq9y0AKmocx3TD
w9DRG2SmKIKBOG5PQuzuXqsdUaYcFpySXdPNQG2CPtguPhQivw4qM3pQpQARAQAB
tCNOb2RlU291cmNlIDxncGctcnBtQG5vZGVzb3VyY2UuY29tPokCOAQTAQIAIgUC
VAI31AIbAwYLCQgHAwIGFQgCCQoLBBYCAwECHgECF4AACgkQXdvo1DT6dN2uaA//
UwKsmnz4MCH7Jn/vG0OinGQTfSH5uvlH68yOZmKLnhtfiqUq1gZz734S75ExxGP4
SGFYeK9CqKFgoGbpjzLLc5kvA7GdDX3E/exEjYa+GrJ9uIOUtaCKstTD5fPVj2Wf
TZtK9v1F6iYKyPHdJnSc5p7AxbLZkarF1CPJQWv2iDrg3dO3Oy41aazRwxJe9hvI
a//XavnsW2TTeo8qfQ0qrs8vzt8bxJF+PkACmqQfbXAiflCct5XEUbhbX1b8KznP
ppd5PLrvRTjHnZi/QRjky0qsUOukGiQhT6iZeiOUcLPeD+f7tA7JBZ08XXRfnLLj
mqYbIHPFG4C/AM5RXu5OdCtFrZQsJgGQEeg/UxYEz5qqNljKjRZ8XsmcyeWouKFM
LuVr1ORF6crl8lAdT3RujP2MzY8cvxJQesYKdWqk3bPXI7oG/PRReoeN86TqraYO
UeTssVlw5lmJtAH+eHt3K6TSjd0rq1RY7xWfttD7L8ECfPmBzbL54MSmKx9MBz+o
a9vOWQ2LjIbR/6DEyQiDpGhQTM+r0/SVS/kqR/j0SEHvOql+sn9sK1/qR1h3JtgI
6YF4IDXBE9s0RBCLbdxtVf3eAcbOnhkhefMtpURJLdVuU8HhMCiVUlHDUPHIuT5z
Lp+avdanIgi8Cnps/DpMI2KigEHW5mmqihXtfKj0jeE=
=9Bql
-----END PGP PUBLIC KEY BLOCK-----
EOF

        fi
        yum install -y nodejs 
        yum install -y gcc-c++ make 
        curl -sL https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo >/dev/null >&1
        yum install -y yarn
        npm install -g cnpm --registry=https://registry.npm.taobao.org
        cnpm install pm2 -g

        if [ `check_rpm nodejs` != '0' ]; then
            echo -e '\033[32;1mnodejs install success\033\0m'
        else
            echo -e '\033[31mnodejs install fail\033[0m'
        fi

    else
        echo -e '\033[31mnodejs already install\033[0m'
    fi

}


case $1 in
  nodejs)
    epel_install
    nodejs_install
    ;;
  *)
    echo "USAGE: $0 nodejs"
    ;;
esac
