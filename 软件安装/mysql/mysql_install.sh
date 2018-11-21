#!/bin/bash
#yousong.xiang 2018.11.21
#v1.0.1
#

[ -f /etc/profile ] && . /etc/profile
[ $# -ne 1 ] && {
                    echo "\033[31m传递参数有误\033[0m"
                    exit 9
                }

cmd=`pwd`

function check_rpm(){
    rpm_name=$1
    num=`rpm -qa|grep ${rpm_name}|wc -l`
    echo ${num}
}

function epel_install(){
    #关闭selinux,安装基础依赖环境函数
    sed -i '/^SELINUX=.*/s/SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux
    setenforce 0
    #判断是否安装redhat-lsb-core
    if [ `check_rpm redhat-lsb-core` == 0 ]; then
        yum install -y redhat-lsb-core  >/dev/null >&1
    fi 

    #重新加载环境变量 
    source /etc/profile 
    sys_ver=`lsb_release -r |awk -F' ' '{print $2}'|awk -F'.' '{ print $1 }'`
    #echo ${sys_ver}    

    #判断是否安装remi-release,如果没有安装则安装
    if [ `check_rpm epel-release` == 0 ]; then
        #rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-${sys_ver}.rpm  &>/dev/null
        #rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm  &>/dev/null
        yum install epel-release -y
        if [ $? -eq 0 ]; then
            echo -e "\033[32;1mepel-release install seccuess\033[0m"
            yum clean all            
        else
            echo -e "\033[31;1mepel-release install fail\033[0m"
        fi
    fi   

}

function mysql56_install() {
    mysql_data=$1
    mysql_conf=/etc/my.conf
    mysql_repo=/etc/yum.repos.d/mysql-community.repo
    mysql_gpg_key=/etc/pki/rpm-gpg/RPM-GPG-KEY-mysql

    if [ `check_rpm redhat-lsb-core` == 0 ]; then
        yum install -y redhat-lsb-core  >/dev/null >&1
    fi

    if [ -f /var/log/mysql_install.lock ]; then
        echo -e "\033[31;1mMysql installed Already \033[0m"
        return 0
    fi    

    #重新加载环境变量 
    source /etc/profile
    sys_ver=`lsb_release -r |awk -F' ' '{print $2}'|awk -F'.' '{ print $1 }'`

    if [ ! -f ${mysql_repo} ]; then
        cat >>${mysql_repo}<< EOF
# Enable to use MySQL 5.6
[mysql56-community]
name=MySQL 5.6 Community Server
baseurl=http://repo.mysql.com/yum/mysql-5.6-community/el/${sys_ver}/\$basearch/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql
EOF
    fi

  if [ ! -f ${mysql_gpg_key} ]; then
      cat >>${mysql_gpg_key}<<EOF
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: PGP Universal 2.9.1 (Build 347)

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
=Eto8
-----END PGP PUBLIC KEY BLOCK-----
EOF
  fi  

  if [ `check_rpm mysql-server` == '0' ]; then
      yum install -y mysql-community-client mysql-community-server mysql-community-devel mysql-community-test  >/dev/null >&1
  fi

  if [ `check_rpm mysql-server` != '0' ]; then
      echo -e "\033[32;1mmysql install seccuess\033[0m"
  else:
      echo -e "\033[31;1mmysql install fail\033[0m"
  fi

  #创建mysql数据库目录
  if [ ! -d ${mysql_data} ]; then
      mkdir -p ${mysql_data}/data
      mkdir -p ${mysql_data}/log
      mkdir -p ${mysql_data}/tmp
      chown -R mysql.mysql ${mysql_data}
  else
      echo "mysql data 目录存在，无需创建."
  fi


  mem_total=`cat /proc/meminfo |grep "MemTotal"|awk '{print $2}'`
  mem_total=`echo "scale=1;${mem_total}/1024/1024"|bc`

  if [ `echo ${mem_total}|awk -F'.' '{print $2}'` -qe 5 ]; then
      let mem_total=`echo ${mem_total}|awk -F'.' '{print $1}'` + 1
  else:
      mem_total=`echo ${mem_total}|awk -F'.' '{print $1}'`
  fi

  let buffer_innodb=mem_total / 2
  

  if [ -f ${mysql_conf} ]; then
      rm -rf {mysql_conf}
      cat >>${mysql_conf}<<EOF
[mysqld_safe]
pid-file=/var/run/mysqld/mysqld.pid


[mysql]
port=3306
prompt=\\\u@\\\d \\\R:\\\m:\\\s>
default-character-set=utf8
no-auto-rehash


[mysqld]

#server
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
#sqlmod="STRICT_ALL_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE"
performance_schema=0

log_slow_admin_statements=1
log_warnings=1
long_query_time=1
slow_query_log=1
general_log=0

query_cache_type=0
query_cache_limit=1M
query_cache_min_res_unit=1K

table_definition_cache=65536
table_open_cache=65536

thread_stack=512K
thread_cache_size=256
read_rnd_buffer_size=128K
sort_buffer_size=256K
join_buffer_size=128K
read_buffer_size=128K

#dir
basedir=${mysql_data}
datadir=${mysql_data}/data
tmpdir=${mysql_data}/tmp
log-error=${mysql_data}/alert.log
slow_query_log_file=${mysql_data}/log/slow.log
#general_log_file=${mysql_data}/log/general.log
socket=/var/lib/mysql/mysql.sock


#binlog
log-bin=${mysql_data}/log/mysql-bin
server_id=1
binlog_cache_size=32K
max_binlog_cache_size=1G
max_binlog_size=500M
binlog_format=ROW
log-slave-updates=1
expire_logs_days=8

#replication
master-info-file=${mysql_data}/log/master.info
relay-log=${mysql_data}/log/relaylog
relay_log_info_file=${mysql_data}/log/relay-log.info
relay-log-index=${mysql_data}/log/mysqld-relay-bin.index
slave_load_tmpdir=${mysql_data}/tmp
slave_net_timeout=4


#innodb
innodb_data_home_dir=${mysql_data}/data
innodb_log_group_home_dir=${mysql_data}/data
innodb_data_file_path=ibdata1:2G;ibdata2:16M:autoextend
innodb_buffer_pool_size=${buffer_innodb}G
innodb_buffer_pool_instances=4
innodb_log_files_in_group=2
innodb_log_file_size=1G
innodb_log_buffer_size=200M
innodb_flush_log_at_trx_commit=2
innodb_additional_mem_pool_size=20M
innodb_max_dirty_pages_pct=60
innodb_io_capacity=1000
innodb_thread_concurrency=16
innodb_read_io_threads=8
innodb_write_io_threads=8
innodb_open_files=60000
innodb_file_format=Barracuda
innodb_file_per_table=1
innodb_flush_method=O_DIRECT
innodb_change_buffering=inserts
innodb_adaptive_flushing=1
innodb_old_blocks_time=1000
innodb_stats_on_metadata=0
innodb_read_ahead=0
innodb_use_native_aio=0
innodb_lock_wait_timeout=5
innodb_rollback_on_timeout=0
innodb_purge_threads=1
innodb_strict_mode=1
innodb_autoinc_lock_mode=0

#myisam
key_buffer_size=64M
myisam_sort_buffer_size=64M
concurrent_insert=2
delayed_insert_timeout=300
EOF
  fi      

  #初始化mysql数据库
  if [ ! -d ${mysql_data}/data/mysql ]; then
      /usr/bin/mysql_install_db --defaults-extra-file=${mysql_conf} --user=mysql --force >/dev/null >&1
      if [ $? = 0 ]; then
          echo  "mysql数据库初始化                            "
      else
          echo 'mysql数据库初始化 fail'
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
  /bin/systemctl start mysqld.service
  firewall-cmd --zone=public --add-service=mysql --permanent
  firewall-cmd --reload

}

case $1 in
mysql)
    mysql_dir=/data/mysql
    mysql56_install ${mysql_dir}
    ;;
*)
    echo "USAG: $0 'mysql'" 
    ;;
esac
