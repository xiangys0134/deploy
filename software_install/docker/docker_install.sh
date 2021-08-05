#!/bin/bash
# Docker安装
# Author yousong.xiang 250919938@qq.com
# Date 2019.4.8,2020.11.25
# v1.0.2

[ -f /etc/profile ] && . /etc/profile

cmd=`pwd`
version='20.10.7'

function check_rpm {
    rpm_package=$1
    package_num=`rpm -qa |grep ${rpm_package}|wc -l`
    #此类判断VSFTPD可以检测到,其他RPM包检测请慎用
    echo ${package_num}
}

function check_install {
    if [ -f /var/log/lock.docker ]; then
        echo -e "\033[31;1mdocker已经安装过,请确认\033[0m"
        exit 1
    fi
}

function check_network {
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

function epel_install {
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

}

function docker_install {
    yum install -y yum-utils device-mapper-persistent-data lvm2
    yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
    if [ $? -ne 0 ]; then
        echo -e "\033[31m添加docker-ce.repo失败\033[0m"
        exit 3
    fi
    yum makecache fast
    yum -y install docker-ce-$version
    if [ $? -ne 0 ]; then
        echo -e "\033[31mdocker安装失败\033[0m"
        exit 4
    fi
    systemctl start docker
    if [ $? -ne 0 ]; then
        echo -e "\033[31mdocker start fail\033[0m"
        exit 4
    fi

    tee /etc/docker/daemon.json <<-'EOF'
{
  "data-root": "/data/docker",
  "storage-driver": "overlay2",
  "registry-mirrors": ["https://yx8zsx76.mirror.aliyuncs.com"]
}
EOF

    if [ ! -d /data/docker ]; then
        mkdir /data/docker -p
    fi
    systemctl daemon-reload
    systemctl restart docker
    systemctl enable docker.service
}

function python_env {
    python3 -V &>/dev/null
    if [ $? -ne 0 ]; then
        yum -y install python36 python36-devel
    fi

    pip3 -V &>/dev/null

    if [ $? -ne 0 ]; then
        if [ ! -f /usr/bin/python3 ]; then
            ln -s /usr/bin/python3.6 /usr/bin/python3
        fi
        yum install -y python36-setuptools python36-six.noarch
        wget -P /tmp/ https://bootstrap.pypa.io/get-pip.py
        if [ $? -ne 0 ]; then
            echo -e "\033[31mdownload get-pip.py fail\033[0m"
            exit 5
        fi
        /usr/bin/python3.6 /tmp/get-pip.py
        pip3 install -i https://pypi.tuna.tsinghua.edu.cn/simple docker-compose
        if [ $? -eq 0 ]; then
             echo -e "\033[32mdocker-compose install seccuess\033[0m"
        fi
    else
        pip3 install -i https://pypi.tuna.tsinghua.edu.cn/simple docker-compose
        if [ $? -eq 0 ]; then
             echo -e "\033[32mdocker-compose install seccuess\033[0m"
        fi
    fi

}

epel_install
docker_install
python_env
