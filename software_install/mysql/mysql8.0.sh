#!/bin/bash
# MySQL8.0一键安装 调整安装源并新增gtid配置
# Author: yousong.xiang
# Date:  2018.11.26 2021.8.4
# Version: v1.0.4


[ -f /etc/profile ] && . /etc/profile
[ $# -ne 1 ] && {
                    echo -e "\033[31;1m 传递参数有误\033[0m"
                    exit 9
                }

cmd=`pwd`
datetime=`date '+%H%M%S'`
log=upgrade${datetime}.log

if [ ! -f ${log} ]; then
    touch ${log}
fi

function check_rpm(){
    rpm_name=$1
    num=`rpm -qa|grep ${rpm_name}|wc -l`
    echo ${num}
}

function epel_install(){
    #关闭selinux,安装基础依赖环境函数
    sed -i '/^SELINUX=.*/s/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
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
            echo -e "\033[32;1m epel-release install seccuess\033[0m"
            yum clean all
        else
            echo -e "\033[31;1m epel-release install fail\033[0m"
        fi
    fi

    if [ `check_rpm wget` == '0' ]; then
        yum install wget -y
        if [ `check_rpm wget` != '0' ]; then
            echo -e "\033[32;1m wget install seccuess\033[0m"
        else
            echo -e "\033[31;1m wget install fail\033[0m"
        fi
    fi

}

function mysql80_install() {
    mysql_data=$1
    mysql_conf=/etc/my.cnf
    mysql_repo=/etc/yum.repos.d/mysql-community.repo
    mysql_gpg_key=/etc/pki/rpm-gpg/RPM-GPG-KEY-mysql


    if [ -f /var/log/mysql_install.lock ]; then
        echo -e "\033[31;1mMysql installed Already \033[0m" |tee -a ${log}
        return 0
    fi

    sys_ver=`lsb_release -r |awk -F' ' '{print $2}'|awk -F'.' '{ print $1 }'`

    if [ -f ${mysql_repo} ]; then
        rm -rf ${mysql_repo}
    fi

    if [ ! -f ${mysql_repo} ]; then
        cat >>${mysql_repo}<< EOF
[mysql8.0-community]
name=MySQL 8.0 Community Server
baseurl=http://repo.mysql.com/yum/mysql-8.0-community/el/${sys_ver}/\$basearch/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql
EOF
    fi

  if [ ! -f ${mysql_gpg_key} ]; then
      wget http://repo.mysql.com/RPM-GPG-KEY-mysql -O /etc/pki/rpm-gpg/RPM-GPG-KEY-mysql

  fi

  yum clean all;rm -rf /var/cache/yum

  if [ `check_rpm mysql-server` == '0' ]; then
      yum install -y mysql-community-client mysql-community-server mysql-community-devel mysql-community-test
  fi

  if [ `check_rpm mysql-server` != '0' ]; then
      echo -e "\033[32;1m mysql install seccuess\033[0m"
  else:
      echo -e "\033[31;1m mysql install failed\033[0m"
  fi

  [ ! -d ${mysql_data}/data ] && mkdir -p ${mysql_data}/data
  [ ! -d ${mysql_data}/log ] && mkdir -p ${mysql_data}/log
  [ ! -d ${mysql_data}/tmp ] && mkdir -p ${mysql_data}/tmp

  chown -R mysql.mysql ${mysql_data}
  mem_total=`free -m|grep "^Mem"|awk '{print $2}'`


  if [ -n ${mem_total} ]; then
      let buffer_innodb=${mem_total}/4
  else
      buffer_innodb=256
  fi

  buffer_innodb=${buffer_innodb}M


  if [ -f ${mysql_conf} ]; then
      mv /etc/my.cnf /etc/my.cnfbak
      cat >>${mysql_conf}<<EOF
[mysqld_safe]
pid-file=/var/run/mysqld/mysqld.pid
[mysql]
port=3306
prompt=\\u@\\d \\R:\\m:\\s>
default-character-set=utf8
no-auto-rehash
[mysqld]
port=3306
bind-address=0.0.0.0
skip-name-resolve
skip-ssl
sql_mode=""
max_connections=4500
max_user_connections=4000
max_connect_errors=65536
max_allowed_packet=128M
connect_timeout=8
net_read_timeout=30
net_write_timeout=60
back_log=1024
default-storage-engine=INNODB
character-set-server=utf8mb4
lower_case_table_names=1
skip-external-locking
open_files_limit=65536
safe-user-create
local-infile=1
performance_schema=0
log_slow_admin_statements=1
long_query_time=1
slow_query_log=1
general_log=0
table_definition_cache=65536
table_open_cache=65536
thread_stack=512K
thread_cache_size=256
read_rnd_buffer_size=128K
sort_buffer_size=256K
join_buffer_size=128K
read_buffer_size=128K
datadir=${mysql_data}/data
tmpdir=${mysql_data}/tmp
log-error=${mysql_data}/alert.log
slow_query_log_file=${mysql_data}/log/slow.log
socket=/var/lib/mysql/mysql.sock
log-bin=/data/mysql/log/mysql-bin
server_id=1
binlog_cache_size=32K
max_binlog_cache_size=1G
max_binlog_size=500M
binlog_format=ROW
log-slave-updates=1
expire_logs_days=30
master-info-file=${mysql_data}/log/master.info
relay-log=${mysql_data}/log/relaylog
relay_log_info_file=${mysql_data}/log/relay-log.info
relay-log-index=${mysql_data}/log/mysqld-relay-bin.index
slave_load_tmpdir=${mysql_data}/tmp
slave_net_timeout=4
innodb_data_home_dir=/data/mysql/data
innodb_log_group_home_dir=/data/mysql/data
innodb_data_file_path=ibdata1:2G;ibdata2:16M:autoextend
innodb_buffer_pool_size=128M
innodb_buffer_pool_instances=4
innodb_log_files_in_group=2
innodb_log_file_size=1G
innodb_log_buffer_size=200M
innodb_flush_log_at_trx_commit=2
innodb_max_dirty_pages_pct=60
innodb_io_capacity=1000
innodb_thread_concurrency=16
innodb_read_io_threads=8
innodb_write_io_threads=8
innodb_open_files=60000
innodb_file_per_table=1
innodb_flush_method=O_DIRECT
innodb_change_buffering=inserts
innodb_adaptive_flushing=1
innodb_old_blocks_time=1000
innodb_stats_on_metadata=0
innodb_use_native_aio=0
innodb_lock_wait_timeout=5
innodb_rollback_on_timeout=0
innodb_purge_threads=1
innodb_strict_mode=1
innodb_autoinc_lock_mode=0
key_buffer_size=64M
myisam_sort_buffer_size=64M
concurrent_insert=2
delayed_insert_timeout=300
EOF
  fi

  #初始化mysql数据库
  if [ ! -d ${mysql_data}/data/mysql ]; then
      #/usr/bin/mysql_install_db --defaults-extra-file=${mysql_conf} --user=mysql --force >/dev/null >&1
      #echo ${mysql_conf}
      /usr/sbin/mysqld --defaults-file=/etc/my.cnf --initialize --user=mysql
      if [ $? -eq 0 ]; then
          echo  "mysql数据库初始化成功"
      else
          echo "mysql数据库初始化 failed"
      fi
  else
      echo "mysql数据库已初始化，无需再次初始化."
  fi

  if [ -f /usr/my.cnf ]; then
      rm -f /usr/my.cnf
  fi
  #修正Centos7 mysql连接数限制
  cat >>/usr/lib/systemd/system/mysqld.service<< EOF
LimitNOFILE=65535
LimitNPROC=65535
EOF
  #添加mysql 服务开机自启动
  /bin/systemctl daemon-reload
  /bin/systemctl enable mysqld.service
  #/bin/systemctl start mysqld.service
  firewall-cmd --zone=public --add-service=mysql --permanent
  firewall-cmd --reload

  if [ `check_rpm mysql-community-server` != '0' ]; then
      echo "mysql-community-server install seccuess" |tee -a ${log}
      touch /var/log/mysql_install.lock
  fi

}

case $1 in
db)
    epel_install
    mysql_dir=/data/mysql
    mysql80_install ${mysql_dir}
    ;;
*)
    echo "USAG: $0 'mysql'"
    ;;
esac
