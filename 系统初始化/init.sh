#!/bin/bash
source /etc/profile
:<<COMMENT
.... Author: xiao.li yousong.xiang
.... Date: 2020-02-10 2021.1.27
.... version:0.0.1
.... Description: Centos7初始化脚本,局部功能调整
.... Alter:
COMMENT
################################################################
#环境检测
function env_check() {
  if [ -f /var/log/init.log ];then
    echo -e "\033[31;49;1m[`date +%F' '%T`] Error: 此系统已经初始化过,请检查。 \033[39;49;0m"
    echo -e "\033[31;49;1m[`date +%F' '%T`] Error: 上次初始化时间为 `awk  '{print $1,$2}' /var/log/init.log` \033[39;49;0m"
    sleep 5s
    exit 1
  fi
  if [ $(id -u) -ne 0 ];then
    echo '=== 此脚本需要root用户执行，即将退出脚本 ==='
    sleep 5s
    exit 2
  fi
  if (! ping -c1 -w20 www.baidu.com > /dev/null 2>&1);then
    echo '=== 访问internet异常，即将退出脚本 ==='
    sleep 5s
    exit 3
  fi
  export install_bak_path='/opt/install_bak'
  #export white_list='59.37.47.22,183.62.140.90'
  export opadm_set_stat='opadm_set_stat'
  [ -d ${install_bak_path} ] || mkdir -p ${install_bak_path}
  [ -f ${install_bak_path}/${opadm_set_stat} ] || touch ${install_bak_path}/${opadm_set_stat}
}

#同步系统时间
function set_date() {
  timedatectl set-timezone Asia/Shanghai >/dev/null >&1
  yum -y install epel-release ntp  >/dev/null >&1
  /usr/sbin/ntpdate cn.pool.ntp.org >/dev/null >&1
  echo "* 4 * * * /usr/sbin/ntpdate cn.pool.ntp.org > /dev/null 2>&1" >> /var/spool/cron/root
  systemctl  restart crond.service >/dev/null >&1
}

#安装基本软件
function install_base_soft() {
  yum install -y http://rpms.famillecollet.com/enterprise/remi-release-7.rpm >/dev/null >&1
  #bsoft_list=(man yum-plugin-fastestmirror vim-enhanced ntp wget bash-completion elinks lrzsz unix2dos dos2unix git unzip python python-devel python-pip net-tools)
  #for basesoft in ${bsoft_list[*]};do rpm -q "$basesoft" > /dev/null || yum -y install "$basesoft" >/dev/null >&1;done
  yum install -y man yum-plugin-fastestmirror vim-enhanced ntp wget bash-completion elinks lrzsz unix2dos dos2unix git unzip python python-devel python-pip net-tools >/dev/null >&1
}

#添加su用户
function set_su_admin() {
  ADMGROUP=opadm
  ADMUSER=opadm
  if (! id "$ADMUSER" > /dev/null 2>&1);then
    groupadd "$ADMGROUP" >/dev/null >&1 && useradd -g "$ADMGROUP" -G wheel "$ADMUSER" >/dev/null >&1 && \
    echo "$ADMUSER:\$6\$75s94X0p\$qrr9ahVu0OeeGXc92QwD3/2H2be.ZWAsEr9/j5O6EIcSwccpc7Utb.kGX03lmZWmR/jldHiSFdjY.S.gsA/jA0" | chpasswd -e && \
    sed -i '/pam_wheel.so\ use_uid/s/\#auth/auth/' /etc/pam.d/su && echo -e "root:\t$ADMUSER" >> /etc/aliases && newaliases
    echo "add user: $ADMUSER " >/dev/null >&1
    chmod 700 /etc/sudoers
    echo "$ADMUSER    ALL=(ALL)    NOPASSWD:ALL" >> /etc/sudoers
    chmod 440 /etc/sudoers
  fi
}

#设置sudoers
function set_su_default_tty() {
  if (grep -q '^Defaults    requiretty$' /etc/sudoers);then
    chmod 700 /etc/sudoers
    sed -i '/^Defaults    requiretty$/s/^/#/' /etc/sudoers
    chmod 440 /etc/sudoers
  fi
}

#设置ssh禁止root登录
function set_sshroot() {
  if (! grep -qE '^###ops_diy_flag_sshroot$' /etc/ssh/sshd_config);then
    echo '###ops_diy_flag_sshroot' >> /etc/ssh/sshd_config
    if [ $(grep '^PermitRootLogin\ \+yes\ *$' /etc/ssh/sshd_config|wc -l) -ge 1 ];then
      sed -i "s/^PermitRootLogin\ \+yes\ *$/PermitRootLogin\ no/" /etc/ssh/sshd_config
    elif [ $(grep '^#PermitRootLogin\ \+yes\ *$' /etc/ssh/sshd_config|wc -l) -ge 1 ];then
      sed -i "s/^#PermitRootLogin\ \+yes\ *$/PermitRootLogin\ no/" /etc/ssh/sshd_config
    elif [ $(grep '^[#]\{2,\}PermitRootLogin\ \+yes\ *$' /etc/ssh/sshd_config|wc -l) -ge 1 ];then
      sed -i "s/[#]\{2,\}PermitRootLogin\ \+yes\ *$/PermitRootLogin\ no/" /etc/ssh/sshd_config
    else
      echo 'PermitRootLogin no' >> /etc/ssh/sshd_config
    fi
    if (sshd -t);then
      systemctl restart sshd.service >/dev/null >&1
    else
      echo " sshd_config 配置文件有错误，请检查配置，即将退出脚本 "
      exit 4
    fi
  fi
}

#设置ssh端口
function set_sshport(){
  export mysshlistenport='21235'
  if (! grep -qE '^###ops_diy_flag_sshport$' /etc/ssh/sshd_config);then
    echo '###ops_diy_flag_sshport' >> /etc/ssh/sshd_config
    if [ $(grep '^Port\ \+[0-9]\{2,5\}\ *$' /etc/ssh/sshd_config|wc -l) -eq 1 ];then
      sed -i "s/^Port\ \+[0-9]\{2,5\}\ *$/Port ${mysshlistenport}/" /etc/ssh/sshd_config
    elif [ $(grep '^Port\ \+[0-9]\{2,5\}\ *$' /etc/ssh/sshd_config|wc -l) -ge 2 ];then
      sed -i "/^Port\ \+[0-9]\{2,5\}\ *$/s/^/#/" /etc/ssh/sshd_config
      sed -i "0,/^#Port\ \+[0-9]\{2,5\}\ *$/s//Port ${mysshlistenport}/" /etc/ssh/sshd_config
    elif [ $(grep '^#Port\ \+[0-9]\{2,5\}\ *$' /etc/ssh/sshd_config|wc -l) -eq 1 ];then
      sed -i "s/^#Port\ \+[0-9]\{2,5\}\ *$/Port ${mysshlistenport}/" /etc/ssh/sshd_config
    elif [ $(grep '^#Port\ \+[0-9]\{2,5\}\ *$' /etc/ssh/sshd_config|wc -l) -ge 2 ];then
      sed -i "/^#Port\ \+[0-9]\{2,5\}\ *$/s/^/#/" /etc/ssh/sshd_config
      sed -i "0,/^#Port\ \+[0-9]\{2,5\}\ *$/s//Port ${mysshlistenport}/" /etc/ssh/sshd_config
    fi
    sed -i  "s/^#UseDNS yes/UseDNS no/" /etc/ssh/sshd_config
    if (sshd -t);then
      echo " sshd_config 配置文件正确 " >/dev/null >&1
      #systemctl restart sshd.service >/dev/null >&1
    else
      echo " sshd_config 配置文件有错误，请检查配置，即将退出脚本 "
      exit 4
    fi
  fi
}

#设置limits
function systemd() {
  mkdir -p /etc/systemd/system.conf.d/ >/dev/null >&1
  cat << EOF >/etc/systemd/system.conf.d/limits.conf
[Manager]
DefaultLimitNOFILE=65535
EOF
  systemctl daemon-reexec >/dev/null >&1
}

#设置防火墙服务
function set_iptables() {
  #判断是否开启防火墙
  firewall-cmd --list-all &>/dev/null
  if [ $? -ne 0 ]; then
    return 4
  fi
  systemctl enable firewalld.service >/dev/null >&1
  systemctl restart firewalld.service  >/dev/null >&1
}

#设置防火墙规则
function set_iptrules(){
#判断是否开启防火墙
firewall-cmd --list-all &>/dev/null
if [ $? -ne 0 ]; then
  return 4
fi
#开放http协议
firewall-cmd --permanent --zone=public --add-service=http >/dev/null >&1
#禁ping
#firewall-cmd --add-rich-rule='rule protocol value=icmp drop' --permanent
#禁止开放ssh服务端口
#firewall-cmd --permanent --zone=public --remove-service=ssh
#开放ssh服务
firewall-cmd --permanent --zone=public --add-port=21235/tcp >/dev/null >&1
#允许某ip段访问ssh端口
#firewall-cmd --permanent --zone=public --add-rich-rule="rule family="ipv4" source address="10.98.0.0/24" service name="ssh" accept"
#firewall-cmd --permanent --zone=public --add-rich-rule="rule family="ipv4" source address="192.168.142.166" port protocol="tcp" port="6379" accept"
#重新加载防火墙配置
firewall-cmd --reload >/dev/null >&1
}

#禁用selinux
function set_selinux() {
  if [ $(grep -cE '^SELINUX=disabled$' /etc/selinux/config) -eq 0 ];then
    /usr/sbin/setenforce 0
    sed -i '/^SELINUX=/s/SELINUX=.*/SELINUX=disabled/' /etc/selinux/config >/dev/null >&1
    echo "selinux is disabled,you must reboot!"  >/dev/null >&1
  fi
}

#设置中文语言
function set_lang_cn() {
  grep -q 'zh_CN.UTF-8' /etc/locale.conf || sed -i -E 's/^LANG=.*/LANG="zh_CN.UTF-8"/' /etc/locale.conf
}

#配置内核参数
function set_sysctl() {
  grep -qE '^###ops_diy_flag_limits$' /etc/security/limits.conf || \
  echo "###ops_diy_flag_limits
  *    soft    nofile    52100
  *    hard    nofile    52100
  *    soft    nproc    32768
  *    hard    nproc    65536
  *    soft    core    0" >> /etc/security/limits.conf

  [ -f /etc/sysctl.conf ] || touch /etc/sysctl.conf

  if (! grep -qE '^###ops_diy_flag_sysctl$' /etc/sysctl.conf);then
    mv /etc/sysctl.conf /etc/sysctl.conf_bak
    iMyRam=`free -m|grep Mem:|awk '{print $2}'`
    ikernel_shmmax=`expr $iMyRam \* 1024 \* 1024 \* 80 \/ 100`
    echo "###ops_diy_flag_sysctl
    net.ipv4.ip_forward = 0
    net.ipv4.conf.default.rp_filter = 1
    net.ipv4.conf.default.accept_source_route = 0
    kernel.sysrq = 0
    kernel.core_uses_pid = 1
    net.ipv4.tcp_syncookies = 1
    kernel.msgmnb = 65536
    kernel.msgmax = 65536
    #kernel.shmmax = ${ikernel_shmmax}
    #kernel.shmall = 134217728
    #net.ipv4.ip_local_port_range = 10240 63535
    #net.ipv4.ip_local_reserved_ports = 10241, 10242-12000
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
    #net.nf_conntrack_max = 524288
    net.ipv4.tcp_fin_timeout = 30
    #net.ipv4.tcp_tw_reuse = 1
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
    kernel.ctrl-alt-del = 1" > /etc/sysctl.conf
    sysctl -p /etc/sysctl.conf >/dev/null >&1
  fi
}

#分区
function set_op_fdisk() {

op_dlabel='op_data'
op_mount_dst='/data'

if $(fdisk -l | grep -q "${1}");then
    :
else
    echo "=== 目标磁盘不存在 ==="
    return 4
fi

part_num=$(fdisk -l $1 | grep -o "^$1[1-9]\>" | tr -d [[:punct:]] | tr -d 'A-Za-z' | sort -n | tail -1)

if [ -z ${part_num} ];then
    fdisk $1 &> ${install_bak_path}/fdisk.log <<EOF
n
p
1
1


w
EOF

	mkfs.xfs -f ${1}1
    [ -d ${op_mount_dst} ] || mkdir -p ${op_mount_dst}
    grep -q "${1}1" /etc/fstab || echo "${1}1    ${op_mount_dst}    xfs    defaults    0 0" >>/etc/fstab
    mount -a && mount && df -h

	elif [ ${part_num} -ge 1 ];then
    echo ''
    echo '=== 目标磁盘分区数量不为零，为保护数据不进行分区 ==='
    echo ''
    return 5
fi

}

#初始化日志
function set_logs(){
  echo `date +%F' '%T` 服务器初始化完成  >>/var/log/init.log
  chattr +i /var/log/init.log
}

#main函数入口函数
function main() {
  pids=""
  echo -e '正在初始化操作系统:'
  echo -ne '#..........................................................................................................  (1%)   [环境检测]\r'
  sleep .5
  #环境检测
  env_check
  pids+=($!)
  echo -ne '#########..................................................................................................  (8%)   [同步系统时间]\r'
  sleep .5
  #同步系统时间
  set_date
  pids+=($!)
  echo -ne '##################.........................................................................................  (16%)   [禁用selinux]\r'
  sleep .5
  #禁用selinux
  set_selinux
  pids+=($!)
  echo -ne '###########################................................................................................  (24%)   [安装基本软件]\r'
  sleep .5
  #安装基本软件
  install_base_soft
  pids+=($!)
  echo -ne '####################################.......................................................................  (32%)   [添加su用户]\r'
  sleep .5
  #添加su用户
  set_su_admin
  pids+=($!)
  echo -ne '############################################...............................................................  (40%)   [设置sudoers]\r'
  sleep .5
  #设置sudoers
  set_su_default_tty
  pids+=($!)
  echo -ne '#####################################################......................................................  (48%)   [设置禁止root登录]\r'
  sleep .5
  #设置ssh禁止root登录
  set_sshroot
  pids+=($!)
  echo -ne '#############################################################..............................................  (56%)   [设置ssh端口]\r'
  sleep .5
  #设置ssh端口
  set_sshport
  pids+=($!)
  echo -ne '###################################################################.........................................  (64%)   [设置limits]\r'
  sleep .5
  #设置limits
  systemd
  pids+=($!)
  echo -ne '##########################################################################..................................  (72%)   [设置防火墙服务]\r'
  sleep .5
  #设置防火墙服务
  set_iptables
  pids+=($!)
  echo -ne '##################################################################################..........................  (80%)   [设置防火墙规则]\r'
  sleep .5
  #设置防火墙规则，阿里云、aws默认firewalld关闭状态
  set_iptrules
  pids+=($!)
  #echo -ne '###########################################################################################.................  (88%)   [设置中文语言]\r'
  #sleep .5
  #设置中文语言
  #set_lang_cn
  #pids+=($!)
  echo -ne '################################################################################################............  (93%)   [配置内核参数]\r'
  sleep .5
  #配置内核参数
  set_sysctl
  pids+=($!)
  echo -ne '######################################################################################################......  (98%)   [初始化成功日志]\r'
  sleep .5
  #初始化成功日志
  set_logs
  pids+=($!)
  echo -ne '############################################################################################################  (100%)   [初始化完成了,请重启服务器]\r'
  sleep .5
  #请重启服务器
  sleep 2
}
main
