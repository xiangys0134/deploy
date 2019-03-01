#!/bin/bash
# yousong.xiang 250919938@qq.com
# 2019.3.1
# v1.0.1
# vsftpd安装脚本

[ -f /etc/profile ] && . /etc/profile

cmd=`dirname $0`
WEBDEV=/data/smb/webdev
FILESHARE=/data/smb/fileshare
SMB_CONF=/etc/samba/smb.conf

function check_rpm() {
    rpm_package=$1
    package_num=`rpm -qa ${rpm_package}|wc -l`
    #此类判断SMB可以检测到,其他RPM包检测请慎用
    echo ${package_num}
}

function check_install() {
    if [ -f /var/log/smb.lock ]; then
        echo -e "\033[31;1mSMB软件已经安装过,请确认\033[0m"
        exit 1
    fi
}

function check_ping() {
    num=`check_rpm samba`
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

function selinux() {
    sed -i '/^SELINUX=enforcing$/c\SELINUX=disabled' /etc/selinux/config
    setenforce 0
}

function smb_install() {
    yum install -y samba samba-client &>/dev/null
    num=`check_rpm samba`
    if [ "${num}" == "0" ]; then
        echo -e "\033[31;1mRPM包安装失败,请rpm -qa samba查看确认\033[0m"
        exit 2
    fi
    
    systemctl start smb nmb &>/dev/null    
}


function smb_config() {
    if [ -f ${SMB_CONF} ]; then
        mv ${SMB_CONF} ${SMB_CONF}bak
    fi

    zuser=ted
    zgroup=co3
    zpass=`echo $RANDOM|md5sum |cut  -c 1-9`

    echo "字符串值填写时，请不要使用火星文等反人类识别字符"

    read -t 30 -p "请输入SMB用户名,回车默认用户名[${zuser}]：" user
    read -t 30 -p "请输入SMB密码,回车默认随机生成密码[${zpass}]：" pass
    read -t 30 -p "请输入SMB用户组名,回车默认group[${zgroup}]" group
    
    user=${user:-${zuser}}
    group=${group:-${zgroup}}
    pass=${pass:-${zpass}}

    #创建用户名密码
    if [ `grep ${group} /etc/group |wc -l` -eq 0 ]; then
        groupadd ${group}
    fi

    id ${user} &>/dev/null
    if [ $? -ne 0 ]; then
        useradd ${user} -g ${group} -s /sbin/nologin
        #(echo ${pass} ; echo ${pass}) | smbpasswd -s -e ${user}
        echo -e "${pass}\n${pass}" | smbpasswd -s -a  ${user}
    fi
    echo -e "${pass}\n${pass}" | smbpasswd -s -a  ${user}
    echo -e "\033[32;1m用户名：${user}\033[0m" 
    echo -e "\033[32;1m密码：${pass}\033[0m"
    
    
    while true
    do
        read -p "确认是否需要创建匿名可写共享[y|n]：" sharefile
        case ${sharefile} in
          y|Y)
            mkdir ${FILESHARE} -p 
            chown nobody:nobody ${FILESHARE}
            echo "选择创建共享目录,共享路径生成中mkdir ${FILESHARE}"
            break
            ;;
          n|N)
            echo "你选择了不创建匿名共享"
            break
            ;;
          *)
            echo "请输入正确的值[y|n]"
            continue
            ;;
        esac
    done
    
   
    read -p "请输入创建共享文件夹名称,回车默认生成为文件夹["${WEBDEV##*/}"]：" SMB_WEBDEV
    SMB_WEBDEV=${SMB_WEBDEV:-${WEBDEV}}
    mkdir ${SMB_WEBDEV} -p

    #文件目录授权
    chown ${user}:${group} ${SMB_WEBDEV}

   if [ "${sharefile}" == "y" -o "${sharefile}" == "Y" ]; then

    cat >>${SMB_CONF}<<EOF
[global]
        workgroup = WORKGROUP
        server string = Ted Samba Server %v
        netbios name = TedSamba
        security = user
        map to guest = Bad User
        passdb backend = tdbsam

[FileShare]
        comment = share some files
        path = ${FILESHARE}
        public = yes
        writeable = yes
        create mask = 0644
        directory mask = 0755

[WebDev]
        comment = project development directory
        path = ${WEBDEV}
        valid users = ${user}
        force group = ${group}
        write list = ${user}
        printable = no
        create mask = 0644
        directory mask = 0755
EOF

    else

    cat >>${SMB_CONF}<<EOF
[global]
        workgroup = WORKGROUP
        server string = Ted Samba Server %v
        netbios name = TedSamba
        security = user
        map to guest = Bad User
        passdb backend = tdbsam


[WebDev]
        comment = project development directory
        path = ${WEBDEV}
        valid users = ${user}
        force group = ${group}
        write list = ${user}
        printable = no
        create mask = 0644
        directory mask = 0755
EOF
    
    fi


}


function systemctl_service() {
    systemctl restart smb nmb
    systemctl enable smb nmb &>/dev/null
    touch /var/log/smb.lock
} 


function firewalld() {
    firewall-cmd --list-all &>/dev/null
    if [ $? -eq 0 ]; then
        firewall-cmd --zone=public --add-port=139/tcp --permanent &>/dev/null
        firewall-cmd --zone=public --add-port=445/tcp --permanent &>/dev/null
        firewall-cmd --reload &>/dev/null
    fi
}

#--------------------------------------------------------------
check_ping	
check_install
selinux
smb_install
smb_config
systemctl_service
firewalld

