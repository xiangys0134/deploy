#!/bin/bash
#yousong.xiang 2018.9.24
#v1.0.3
#mysql源码编译,默认使用mysql用户作为守护进程
#源码包目录需存放至/tmp目录下 例: /tmp/install_mysql5_7/

[ -f /etc/profile ] && . /etc/profile
[ -f /etc/init.d/functions ] && . /etc/init.d/functions

cmd=`pwd`
mysql_base=/usr/local/mysql
mysql_data=/data/mysql/data
mysql_logdir=/data/mysql/binlog
mysql_code="mysql-5.7.17"
mysql_boost="boost_1_59_0"
soft_dir=/tmp/install_mysql5_7
url='http://xiangys-test.oss-cn-qingdao.aliyuncs.com/deploy/source'

[ ! -d ${mysql_base} ] && mkdir ${mysql_base} -p
[ ! -d ${mysql_data} ] && mkdir ${mysql_data} -p
[ ! -d ${mysql_logdir} ] && mkdir ${mysql_logdir} -p

install_rely() {
    for i in "gcc gcc-c++ cmake ncurses-devel bison dos2unix unzip"
    do
        yum install -y $i
    done
    
}

addusers() {
    id mysql >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        groupadd mysql && useradd -s /sbin/nologin -g mysql -M mysql
        #mysql初始密码:mysql_db123456
        echo ‘mysql:$1$/p8oxLGd$emc8C5bG2.dKQ7oUypY2o0’|chpasswd -e
    fi
}

mysql_make() {
    my_cnf=${mysql_base}/my.cnf
    let MemTotal=`grep "MemTotal" /proc/meminfo|awk '{print $2}'`
    let Mem_set=MemTotal/2/1024
    buffer_size=${buffer_size}M
    cd ${cmd}
    #[ ! -f ${soft_dir}/${mysql_code}.tar.gz ] && echo "${mysql_code}.tar.gz is not exist" && exit 1
    [ -d ${cmd}/${mysql_code} ] && rm -rf ${mysql_code}
    [ -d ${cmd}/${mysql_boost} ] && rm -rf ${mysql_boost}

    if [ ! -f ${cmd}/${mysql_code}.tar.gz ]; then
        echo "${mysql_code}.tar.gz Download..."
        wget ${url}/${mysql_code}.tar.gz
    fi
    
    if [ ! -f ${cmd}/${mysql_boost}.tar.gz ]; then
        echo "${mysql_boost}.tar.gz Download..."
        wget ${url}/${mysql_boost}.tar.gz
    fi
    #cd ${soft_dir} 
    echo "\033[31minstall ${mysql_boost}...\033[0m"
    tar -zxf ${mysql_boost}.tar.gz
    cp -rf ${mysql_boost} /usr/local/
    echo "\033[31minstall ${mysql_code}...\033[0m"
    tar -xzf ${mysql_code}.tar.gz
    cd ${cmd}/${mysql_code}/
    cmake \
    -DMYSQL_USER=mysql \
    -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
    -DINSTALL_DATADIR=/data/mysql/data \
    -DDOWNLOAD_BOOST=1 \
    -DWITH_BOOST=/usr/local/boost_1_59_0/ \
    -DMYSQL_UNIX_ADDR=/usr/local/mysql/mysql.sock \
    -DDEFAULT_CHARSET=utf8 \
    -DDEFAULT_COLLATION=utf8_general_ci \
    -DEXTRA_CHARSETS=all \
    -DWITH_EMBEDDED_SERVER=1 \
    -DENABLED_LOCAL_INFILE=1 \
    -DWITH_MYISAM_STORAGE_ENGINE=1 \
    -DWITH_INNOBASE_STORAGE_ENGINE=1 \
    -DWITH_DEBUG=0
    if [ $? -eq 0 ]; then
        make && make install
    fi
    cd ${mysql_base}
    echo "\033[31mInitialization ${mysql_code}...\033[0m"
    bin/mysql_install_db --basedir=/usr/local/mysql --datadir=/data/mysql/data --user=mysql

    cp -rf ${cmd}/${mysql_code}/support-files/mysql.server /etc/init.d/mysql
    chmod 700 /etc/init.d/mysql
    chkconfig --level 35 mysql on
    export_count=`grep "${mysql_base}/bin/:$PATH" /etc/profile|wc -l` 
    if [ "${export_count}" != "1" ]; then  
        echo "export PATH=${mysql_base}/bin/:$PATH" >> /etc/profile && source /etc/profile
    fi

    [ -f /etc/my.cnf ] && rm -rf /etc/my.cnf
    [ -f ${my_cnf} ] && mv ${my_cnf} /tmp/

cat >>${my_cnf}<< EOF 
[mysqld]
user = mysql
port = 3356
#datadir=/data/mysql/data
datadir = ${mysql_data}
#basedir = /usr/local/mysql
basedir = ${mysql_base}
#socket=/usr/local/mysql/mysql.sock
socket = ${mysql_base}/mysql.sock
log-error = ${mysql_data}/mysql-error.log
pid-file = ${mysql_data}/mysql.pid
back_log = 50
max_connections = 3000
max_connect_errors = 10
table_open_cache = 2048
key_buffer_size = 32M
max_allowed_packet = 64M
expire_logs_days  = 30
max_heap_table_size = 64M
read_buffer_size = 2M
read_rnd_buffer_size = 16M
sort_buffer_size = 8M
join_buffer_size = 8M
thread_cache_size = 8
#thread_concurrency = 8
query_cache_size = 64M
query_cache_limit = 2M
ft_min_word_len = 4
default-storage-engine = INNODB
thread_stack = 192K
transaction_isolation = REPEATABLE-READ
tmp_table_size = 64M
#log_bin=/data/mysql/binlog/mysql-bin
log_bin = ${mysql_logdir}/mysql-bin
binlog_format = mixed
binlog_cache_size = 1M
server_id=1
long_query_time = 5
slow_query_log
slow_query_log_file = ${mysql_data}/slow.log
bulk_insert_buffer_size = 64M
myisam_sort_buffer_size = 128M
myisam_max_sort_file_size = 10G
myisam_repair_threads = 1
#myisam_recover
skip-name-resolve
#skip-innodb
#innodb_additional_mem_pool_size = 16M
#innodb_buffer_pool_size = 512M
innodb_buffer_pool_size = ${buffer_size}
innodb_data_file_path = ibdata1:10M:autoextend
innodb_file_per_table=1
innodb_io_capacity = 2000
innodb_io_capacity_max = 18000
#innodb_file_io_threads = 4
innodb_thread_concurrency = 16
innodb_flush_log_at_trx_commit = 1
innodb_log_buffer_size = 8M
innodb_log_file_size = 256M
innodb_log_files_in_group = 3
innodb_max_dirty_pages_pct = 90
innodb_lock_wait_timeout = 120
wait_timeout = 2880000 
interactive_timeout = 2880000
net_read_timeout = 300
net_write_timeout = 300
log-bin-trust-function-creators = 1
lower_case_table_names = 1
[mysqld_safe]
open-files-limit = 8192
EOF

    chown -R mysql:mysql ${mysql_base}
    chown -R mysql:mysql ${mysql_data}
    chown -R mysql:mysql ${mysql_logdir}    

    service mysql start

}

firewalld_port() {
    echo "add firewalld port..."
    firewalld_state=`firewall-cmd --state`
    if [ "${firewalld_state}" = "running" ]; then
        firewall-cmd --zone=public --add-port=3306/tcp --permanent
        firewall-cmd --reload
    fi
}

install_rely
addusers
mysql_make
firewalld_port
