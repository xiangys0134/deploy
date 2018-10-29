#!/bin/bash
#CentOS7 系统初始化
#yousong.xiang
#v1.0.2
#需求：
#1.检测是否为root
#2.检测是否联网
#3.修改为阿里云源
#4.时区配置及时间同步
#5.安装基本软件
#6.添加用户进行授权免密码登陆root
#7.禁止root登陆
#8.设置ssh端口为2256
#9.设置防火墙默认添加端口2256、80、443
#10.禁止selinux
#11.配置内核参数
#12.修改文件句柄
#
#初始脚本放置在/tmp目录下
[ -f /etc/profile ] && . /etc/profile
[ -f /etc/init.d/functions ] && . /etc/init.d/functions

dictory='/tmp'
cmd=`pwd`
#检查1 2两项
env_check() {
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


mirror() {
    release_id=$(rpm -q centos-release|cut -d- -f3)
    mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
    cd /etc/yum.repos.d
    curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-${release_id}.repo
    yum makecache
    #cd ${dictory}
}

localtime() {
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

install_base_soft() {
    #bsoft_list="man yum-plugin-fastestmirror vim-enhanced ntp wget bash-completion elinks lrzsz unix2dos dos2unix git unzip python python-devel python-pip telnet"
    #for i in ${bsoft_list}; do
    #    yum install -y ${i}
    #done
    cd ${cmd}
    wget https://bootstrap.pypa.io/get-pip.py
    if [ $? -eq 0 ]; then
        python ${cmd}/get-pip.py
    fi
    yum install -y man yum-plugin-fastestmirror vim-enhanced ntp wget bash-completion elinks lrzsz unix2dos dos2unix git unzip python python-devel python-pip telnet

    pip install setuptools
    if [ $? -eq 0 ]; then
        echo -e "\033[32mInstall setuptools seccess\033[0m"
    fi
}

set_su_admin() {
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
set_sshroot() {
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    if [ -f /lib/systemd/system/sshd.service ]; then
        systemctl restart sshd.service
    else
        service sshd restart
    fi
    echo "UseDNS no">>/etc/ssh/sshd_config

}

#设置系统端口为2256
set_sshd_port() {
    port=2256
    sed -i "/^#Port 22/s@#Port 22@Port ${port}@g" /etc/ssh/sshd_config
    if [ $? -eq 0 ]; then
        action "端口更改为:\t${port}" /bin/true
        [ -f /lib/systemd/system/sshd.service ] && systemctl restart sshd.service || service sshd restart
    else
        action "端口更改为:\t${port}" /bin/false  
    fi
}


#添加防火墙,只适配centos7
set_firewalld() {
    if [ -f /lib/systemd/system/firewalld.service ]; then
        systemctl enable firewalld.service 
        systemctl restart firewalld.service
        #开放http协议
        firewall-cmd --permanent --zone=public --add-service=http
        #禁ping
        #firewall-cmd --add-rich-rule='rule protocol value=icmp drop' --permanent
        #禁止开放ssh服务端口
        #firewall-cmd --permanent --zone=public --remove-service=ssh 
        #开放ssh服务
        firewall-cmd --permanent --zone=public --add-port=2256/tcp
        #允许某ip段访问ssh端口
        #firewall-cmd --permanent --zone=public --add-rich-rule="rule family="ipv4" source address="10.98.0.0/24" service name="ssh" accept"
        #重新加载防火墙配置
        firewall-cmd --reload
    fi
}

#关闭
set_selinux() {
    #sed -i '/^SELINUX=enforcing$/s#enforcing#disabled#g' /etc/sysconfig/selinux
    sed -i '/^SELINUX=$/c\SELINUX=disabled' /etc/sysconfig/selinux
}

sysctl_limit() {

cat >/${cmd}/sysctl.txt <<EOF
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
            echo -e "\033[32mConfiguration ${line} seccess\033[0m"
        else
            echo -e "\033[31mConfiguration ${line} failure\033[0m"
        fi
    fi


done < /${cmd}/sysctl.txt

  #echo "$sysctl" >> /etc/sysctl.conf && echo "$sysctl"
}

set_sysctl() {
    if [ -f /etc/sysctl.conf ]; then
        echo "aaa"
        cp /etc/sysctl.conf /etc/sysctl.conf.backup
        sysctl_limit
        sysctl -p /etc/sysctl.conf
    fi 
}

#修改文件句柄
set_limit() {
  max_files="##
* soft nofile 655350
* hard nofile 655350
"

    soft_limit=$(grep 'soft nofile' /etc/security/limits.conf |wc -l)
    soft_limit=$(grep 'hard nofile' /etc/security/limits.conf |wc -l)
    if [ "${soft_limit}" = "0"  -a "${soft_limit}" = "0" ]; then
        echo "${max_files}" >> /etc/security/limits.conf
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

maue() {
cat << EOF
#3.修改为阿里云源
#4.时区配置及时间同步
#5.安装基本软件
#6.添加用户进行授权免密码登陆root
#7.禁止root登陆
#8.设置ssh端口为2256
#9.设置防火墙默认添加端口2256策略
#10.禁止selinux
#11.配置内核参数
#12.修改文件句柄
EOF
}

maue

echo "==初始化完成,请重启系统,并检查初始化项"
