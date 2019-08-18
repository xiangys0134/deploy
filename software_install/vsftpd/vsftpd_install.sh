#!/bin/bash
# yousong.xiang 250919938@qq.com
# 2019.3.1
# v1.0.1
# vsftpd安装脚本

[ -f /etc/profile ] && . /etc/profile

cmd=`dirname $0`
CHROOOT_LIST_DIR=/etc/vsftpd/chroot_list
CONFIG_DIR=/etc/vsftpd/vuser_conf
#PASV_ADDR默认选择内网IP，如果是NAT公网/私网双网卡则配置成公网IP
PASV_ADDR=172.17.238.10
PASV_MIN_PORT=30000
PASV_MAX_PORT=30999
VSFTPD_USER_TXT=/etc/vsftpd/ftpuser.txtx
VSFTPD_USER_DB=/etc/vsftpd/vftpuser.db


function check_rpm() {
    rpm_package=$1
    package_num=`rpm -qa ${rpm_package}|wc -l`
    #此类判断VSFTPD可以检测到,其他RPM包检测请慎用
    echo ${package_num}
}

function check_install() {
    if [ -f /var/log/vsftpd.lock ]; then
        echo -e "\033[31;1mVSFTP软件已经安装过,请确认\033[0m"
        exit 1
    fi
}

function check_ping() {
    num=`check_rpm vsftpd`
    if [ ${num} -ne 0 ]; then
        echo -e "\033[31;1mRPM包已经安装，请确认!\033[0m"
        exit 2
    fi

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

function vsftpd_install() {
    echo "开始yum安装VSFTPD..."
    yum install -y vsftpd &>/dev/null
    if [ $? -ne 0  ]; then
        echo -e "\033[31;1myum安装失败!\033[0m"
        exit 6
    fi
}

function vsftpd_config() {
    #通过ftp匿名登录模式
    echo "[guest_username=ftp]" > ${CHROOOT_LIST_DIR}
    #生成用户名和密码
    userpass=`echo $RANDOM|md5sum |cut  -c 1-8`
    read -p "请输入VSFTPD用户名,默认回车则自动生成用户名[admin]：" -t 30 user
    read -p "请输入VSFTPD密码,默认回车则自动生成密码["${userpass}"]：" -t 30 pass
    user=${user:-admin}
    pass=${pass:-${userpass}}
    
    if [ ! -d /etc/vsftpd ]; then
        echo -e "\033[31;1mVSFTP安装目录不存在,请检测是否安装成功\033[0m"
        exit 7
    fi

    echo "${user}" >>${VSFTPD_USER_TXT}
    echo "${pass}" >>${VSFTPD_USER_TXT}

    #db_load命令系统默认基本都会安装,如果提示未安装则手动yum安装即可
    db_load -T -t hash -f ${VSFTPD_USER_TXT} ${VSFTPD_USER_DB}
    if [ $? -ne 0 ]; then
        echo -e "\033[31;1mdb_load安装配置失败,请确认!\033[0m"
        exit 8
    fi

    #配置pam.d
    mv /etc/pam.d/vsftpd /etc/pam.d/vsftpdbak
    echo "auth required /lib64/security/pam_userdb.so db=/etc/vsftpd/vftpuser" > /etc/pam.d/vsftpd
    echo "account required /lib64/security/pam_userdb.so db=/etc/vsftpd/vftpuser" >> /etc/pam.d/vsftpd
 
    #创建虚拟用户管理目录
    mkdir ${CONFIG_DIR} -p
      cat >>${CONFIG_DIR}/${user}<< EOF
local_root=/data/vsftpd_data/${user}
write_enable=YES
download_enable=YES
anon_world_readable_only=NO
anon_upload_enable=YES
anon_mkdir_write_enable=YES
anon_other_write_enable=YES
anon_umask=022
EOF

    if [ $? -eq 0 ]; then
        mkdir /data/vsftpd_data/${user} -p
        chown -R ftp:ftp /data/vsftpd_data/${user}
    fi 

    #配置VSFTPD配置文件
    if [ -f /etc/vsftpd/vsftpd.conf ]; then
        mv /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.confbak
    fi    

    cat >>/etc/vsftpd/vsftpd.conf<<EOF
anonymous_enable=NO
use_localtime=yes
local_enable=YES
write_enable=NO
local_umask=022
anon_umask=022
allow_writeable_chroot=YES
anon_upload_enable=NO
anon_mkdir_write_enable=NO
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
xferlog_file=/var/log/vsftpd.log
xferlog_std_format=YES
chroot_list_enable=YES
chroot_list_file=${CHROOOT_LIST_DIR}
listen=YES
pam_service_name=vsftpd
userlist_enable=YES
tcp_wrappers=YES
userlist_deny=YES
guest_enable=YES
guest_username=ftp
user_config_dir=${CONFIG_DIR}
pasv_enable=YES
pasv_address=${PASV_ADDR}
pasv_min_port=${PASV_MIN_PORT}
pasv_max_port=${PASV_MAX_PORT}
EOF

    echo "vsftp" > /var/log/vsftpd.lock

    systemctl start vsftpd
    if [ $? -ne 0 ]; then
        echo -e "\033[31;1mVSFTPD启动失败\033[0m"
        echo -e "\033[32;1mVSFTPD用户名：${user}\033[0m" 
        echo -e "\033[32;1mVSFTPD密码：${pass}\033[0m"
        exit 9
    else
        systemctl enable vsftpd &>/dev/null
        echo -e "\033[32;1mVSFTPD用户名：${user}\033[0m" 
        echo -e "\033[32;1mVSFTPD密码：${pass}\033[0m" 
    fi

}


function firewall_cmd() {
    firewall-cmd --list-all &>/dev/null
    if [ $? -eq 0 ]; then
        firewall-cmd --zone=public --add-port=${PASV_MIN_PORT}-${PASV_MAX_PORT}/tcp --permanent &>/dev/null
        firewall-cmd --zone=public --add-port=21/tcp --permanent &>/dev/null
        firewall-cmd --reload &>/dev/null
    fi
}


check_ping
vsftpd_install
vsftpd_config
firewall_cmd
