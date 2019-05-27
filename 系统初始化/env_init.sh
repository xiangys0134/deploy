#!/bin/bash
# CentOS7 系统初始化
# yousong.xiang
# v1.0.3
# 初始脚本放置在/tmp目录下

[ -f /etc/profile ] && . /etc/profile
[ -f /etc/init.d/functions ] && . /etc/init.d/functions

cmd=`pwd`

function maue() {
cat << EOF
#1.修改为阿里云源
#2.时区配置及时间同步
#3.安装基本软件
#4.添加用户进行授权免密码登陆root
#5.禁止root登陆
#6.设置ssh端口为2256
#7.设置防火墙默认添加端口2256策略
#8.禁止selinux
#9.配置内核参数
#10.修改文件句柄
EOF
    echo "初始化完成,请重启系统,并检查初始化项"
}

function env_check() {
    uid=$(id -u)
    if [ ${uid} -ne 0 ]; then
        echo '==此脚本需要root用户执行,程序即将退出.'
        exit 2        
    fi

    ping -c 4 -W 2 www.aliyun.com >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo '网络不通,请检查网络'
        exit 6
    fi 
}


function check_rpm() {
    rpm_name=$1
    num=`rpm -qa|grep ${rpm_name}|wc -l`
    echo ${num}
}


function mirror() {
    release_id=$(rpm -q centos-release|cut -d- -f3)
    mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
    cd /etc/yum.repos.d
    curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-${release_id}.repo
    yum makecache
}

function localtime() {
    rm -rf /etc/localtime
    #ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    timedatectl set-timezone Asia/Shanghai
    yum install -y ntpdate
    /usr/sbin/ntpdate ntp1.aliyun.com
    echo "* 4 * * * /usr/sbin/ntpdate ntp1.aliyun.com > /dev/null 2>&1" >> /var/spool/cron/root
    if [ -f /lib/systemd/system/crond.service ]; then
        systemctl  restart crond.service
    fi
    #centos6 crontab重启
    if [ -f /etc/init.d/crond ]; then
        /etc/init.d/crond restart
    fi 
}

function install_base_soft() {
    yum install -y redhat-lsb-core epel-release 
    yum install -y vim-enhanced ntp wget bash-completion elinks lrzsz unix2dos dos2unix git unzip telnet net-tools python36 python36-devel python36-setuptools python36-six.noarch
    wget -P /tmp/ https://bootstrap.pypa.io/get-pip.py
    /bin/python36 /tmp/get-pip.py && ln -s /bin/python36 /bin/python3 
    /usr/local/bin/pip3 install pandas && /usr/local/bin/pip3 install sxl
    
    if [ $? -eq 0 ]; then
        echo -e "\033[32;1m Install python3.6 seccess\033[0m"
    fi
}

function set_su_admin() {
    ADMGROUP=opadm
    ADMUSER=opadm
    id ${ADMUSER} >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        #默认密码123,可以通过openssl passwd -1 生成加密密码
        groupadd "$ADMGROUP" && useradd -g "$ADMGROUP" -G wheel "$ADMUSER" && \
        echo "$ADMUSER:\$1\$.NrYRpgb\$yi0l8DhS8JbsJLZ2Nz4QJ." | chpasswd -e && \
        sed -i '/pam_wheel.so\ use_uid/s/\#auth/auth/' /etc/pam.d/su && echo -e "root:\t$ADMUSER" >> /etc/aliases && newaliases
        echo "add user: $ADMUSER "

        chmod 700 /etc/sudoers
        echo "$ADMUSER    ALL=(ALL)    NOPASSWD:ALL" >> /etc/sudoers
        chmod 440 /etc/sudoers
    fi
}


#设置ssh禁止root登录
function set_sshroot() {
    setenforce 0
    /bin/cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    sed -i '/#PermitRootLogin yes/s@#PermitRootLogin yes@PermitRootLogin no@g' /etc/ssh/sshd_config
    if [ $? -eq 0 ]; then
        systemctl restart sshd.service
    fi
}

#设置系统端口为2256
set_sshd_port() {
    port=2256
    sed -i "/^#Port 22$/s@#Port 22@Port ${port}@g" /etc/ssh/sshd_config
    if [ $? -eq 0 ]; then
        action "端口更改为:\t${port}" /bin/true
        systemctl restart sshd.service
    else
        action "端口更改为:\t${port}" /bin/false  
    fi
}


#添加防火墙,只适配centos7
set_firewalld() {
    if [ -f /lib/systemd/system/firewalld.service ]; then
        systemctl enable firewalld.service 
        systemctl restart firewalld.service
        firewall-cmd --permanent --zone=public --add-service=http
        firewall-cmd --permanent --zone=public --add-port=2256/tcp
        firewall-cmd --reload
    fi
}

#关闭
function set_selinux() {
    sed -i '/^SELINUX=enforcing$/c\SELINUX=disabled' /etc/selinux/config
}

function sysctl_limit() {

cat >${cmd}/sysctl.txt <<EOF
net.ipv4.ip_forward = 0
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.accept_source_route = 0
kernel.sysrq = 0
kernel.core_uses_pid = 1
net.ipv4.tcp_syncookies = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
net.ipv4.ip_local_port_range = 30000 63535
net.ipv4.tcp_max_tw_buckets = 9000
net.ipv4.tcp_keepalive_time = 180
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 2
net.ipv6.conf.all.disable_ipv6 = 1
net.core.rmem_max = 33554432
net.core.wmem_max = 33554432
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.nf_conntrack_max = 524288
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_tw_recycle = 0
net.core.netdev_max_backlog = 30000
net.core.somaxconn = 65535
net.ipv4.tcp_max_orphans = 262144
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2
vm.swappiness = 5
vm.overcommit_memory = 1
fs.file-max = 4096000
kernel.ctrl-alt-del = 1
EOF

while read line
do
    echo "Modify ${line}..."
    line_less=`echo ${line}|awk '{print $1}'`
    if [ `grep "^${line_less}" /etc/sysctl.conf | wc -l` -ge 1 ]; then
        echo -e "There ${line} Already exist"
        continue
    else
        echo ${line} >> /etc/sysctl.conf
        if [ $? -eq 0 ]; then
            echo -e "\033[32;1m Configuration ${line} seccess \033[0m"
        else
            echo -e "\033[31;1m Configuration ${line} failure \033[0m"
        fi
    fi


done < ${cmd}/sysctl.txt
}

function set_sysctl() {
    if [ -f /etc/sysctl.conf ]; then
        #echo "aaa"
        cp /etc/sysctl.conf /etc/sysctl.conf.backup
        sysctl_limit
        sysctl -p /etc/sysctl.conf
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
        action "文件句柄设置"  /bin/true
    else
        action "文件句柄设置"  /bin/false
    fi
}



##函数调用
env_check
mirror
localtime
install_base_soft
set_su_admin
set_sshroot
set_sshd_port
set_firewalld
set_selinux
set_sysctl
set_limit

maue

