#!/bin/bash
source /etc/profile
:<<COMMENT
.... Author: xiao.li
.... Date: 2020-02-22
.... version:0.0.1
.... Description: Centos7 安装php环境
.... Alter:
COMMENT
################################################################
_version="v0.01"
red='\e[91m'
green='\e[92m'
yellow='\e[93m'
magenta='\e[95m'
cyan='\e[96m'
none='\e[0m'
source /etc/os-release
sys_bit=$(uname -m)
# 检查用户是否是Root用户
[[ $(id -u) != 0 ]] && echo -e " 哎呀……请使用 ${red}root ${none}用户运行 ${yellow}~(^_^) ${none}" && exit 1
# 关闭Selinux
sed  -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
setenforce 0
#判断系统版本
case $ID in
debian|ubuntu|devuan)
  echo -e "
  哈哈……这个 ${red}辣鸡脚本${none} 不支持你的系统。 ${yellow}(-_-) ${none}
  备注: 仅支持 CentOS 6+ 系统
  "
  ;;
centos|rhel)
  cmd="yum"
  ;;
*)
  exit 1
  ;;
esac
#错误函数
error() {
  clear
	echo -e "\n$red 输入错误！$none\n"

}
#暂停函数
pause() {
	read -rsp "$(echo -e "按$green Enter 回车键 $none继续....或按$red Ctrl + C $none取消.")" -d $'\n'
	echo
}
# nginx 配置文件
function nginx_conf(){
  fastcgi_conf=/etc/nginx/fastcgi.conf
  nginx_upstream_conf=/etc/nginx/conf.d/upstream.conf
  nginx_vhost_conf=/etc/nginx/conf.d/default_path_info.conf_default
#生成upstream.conf文件
cat << EOF >${nginx_upstream_conf}
upstream web {
server unix:/var/run/php-fpm/php-fpm-web1.sock;
}
EOF
#生成fastcgi.conf文件
cat << EOF >${fastcgi_conf}
fastcgi_param  SCRIPT_FILENAME    \$document_root\$fastcgi_script_name;
fastcgi_param  QUERY_STRING       \$query_string;
fastcgi_param  REQUEST_METHOD     \$request_method;
fastcgi_param  CONTENT_TYPE       \$content_type;
fastcgi_param  CONTENT_LENGTH     \$content_length;

fastcgi_param  SCRIPT_NAME        \$fastcgi_script_name;
fastcgi_param  REQUEST_URI        \$request_uri;
fastcgi_param  DOCUMENT_URI       \$document_uri;
fastcgi_param  DOCUMENT_ROOT      \$document_root;
fastcgi_param  SERVER_PROTOCOL    \$server_protocol;
fastcgi_param  REQUEST_SCHEME     \$scheme;
fastcgi_param  HTTPS              \$https if_not_empty;

fastcgi_param  GATEWAY_INTERFACE  CGI/1.1;
fastcgi_param  SERVER_SOFTWARE    nginx/\$nginx_version;

fastcgi_param  REMOTE_ADDR        \$remote_addr;
fastcgi_param  REMOTE_PORT        \$remote_port;
fastcgi_param  SERVER_ADDR        \$server_addr;
fastcgi_param  SERVER_PORT        \$server_port;
fastcgi_param  SERVER_NAME        \$server_name;

# PHP only, required if PHP was built with --enable-force-cgi-redirect
fastcgi_param  REDIRECT_STATUS    200;
# fastcgi_param  PHP_VALUE      "open_basedir=\$document_root:/tmp/";
EOF
#生成nginx虚拟站点配置文件
cat << EOF >${nginx_vhost_conf}
#nginx 虚拟主机模板,开启pathinfo。
server {
    listen              80;
    #listen            443;
    server_name         test.com;
    index index.php index.html;
    charset utf8;
    gzip_min_length 1024;
    client_max_body_size    1000m;
    #ssl on;
    #ssl_certificate /data/virtualhost/test/ssl/test.pem;
    #ssl_certificate_key /data/virtualhost/test/ssl/test.key;
    #ssl_session_timeout 5m;
    #ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4;
    #ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    #ssl_prefer_server_ciphers on;


    location / {
        charset utf8;
        root /data/virtualhost/test/wwwroot/web;
    if (-f \$request_filename) {
            break;
        }
        if (!-e \$request_filename){
            rewrite ^/(.*)\$ /index.php/\$1 last;
        }
    }

    location ~ .*\.php[/]? {
    root /data/virtualhost/test/wwwroot/web;
    include        fastcgi.conf;
    proxy_no_cache 1;
    proxy_store off;
    proxy_cache off;
    tcp_nodelay    on;
    fastcgi_pass   web;
    fastcgi_index index.php;
    fastcgi_connect_timeout 200;
    fastcgi_send_timeout 200;
    fastcgi_read_timeout 200;
    fastcgi_buffer_size 128k;
    fastcgi_buffers 4 256k;
    fastcgi_split_path_info ^(.+\.php)(.*)\$;
    fastcgi_param   SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    fastcgi_param   PATH_INFO      \$fastcgi_path_info;
    fastcgi_param   PATH_TRANSLATED \$document_root\$fastcgi_path_info;
    }
    #设置访问日志和错误日志
    access_log /data/virtualhost/test/logs/access.log main;
    error_log /data/virtualhost/test/logs/error.log warn;
}
EOF
}
#php配置文件
function php_fpm_conf(){
  php_fpm_cf=/etc/php-fpm.d/web1.conf
cat << EOF >${php_fpm_cf}
[web]
;fpm监听端口，即nginx中php处理的地址，一般默认值即可。可用格式为: 'ip:port', 'port', '/path/to/unix/socket'. 每个进程池都需要设置。如果nginx和php在不同的机器上，分布式处理，就设置ip这里就可以了。
;listen = 127.0.0.1:9000
listen = /var/run/php-fpm/php-fpm-web1.sock
;listen.allowed_clients = 127.0.0.1
;允许访问FastCGI进程的IP白名单，设置any为不限制IP，如果要设置其他主机的nginx也能访问这台FPM进程，listen处要设置成本地可被访问的IP。默认值是any。每个地址是用逗号分隔. 如果没有设置或者为空，则允许任何服务器请求连接。
;backlog数，设置 listen 的半连接队列长度，-1表示无限制，由操作系统决定，此行注释掉就行。
listen.backlog = 2048
;unix socket设置选项，如果使用tcp方式访问，这里注释即可。
listen.owner = nginx
listen.group = nginx
listen.mode = 0666
;启动进程的用户和用户组，FPM 进程运行的Unix用户, 必须要设置。用户组，如果没有设置，则默认用户的组被使用。
user = nginx
group = nginx
;每一个请求的访问日志，默认是关闭的。
;access.log = log/.access.log
;设定访问日志的格式。
;access.format = "%R - %u %t \"%m %r%Q%q\" %s %f %{mili}d %{kilo}M %C%%"
;php-fpm进程启动模式，pm可以设置为static和dynamic和ondemand 如果选择static，则进程数就数固定的，由pm.max_children指定固定的子进程数。
pm = dynamic
;如果选择dynamic，则进程数是动态变化的,由以下参数决定：
pm.max_children = 30                                                                  ;子进程最大数
pm.start_servers = 15                                                                 ;启动时的进程数，默认值为: min_spare_servers + (max_spare_servers - min_spare_servers) / 2
pm.min_spare_servers = 15                                                             ;保证空闲进程数最小值，如果空闲进程小于此值，则创建新的子进程
pm.max_spare_servers = 30                                                             ;保证空闲进程数最大值，如果空闲进程大于此值，此进行清理
pm.max_requests = 20480                                                               ;设置每个子进程重生之前服务的请求数. 对于可能存在内存泄漏的第三方模块来说是非常有用的. 如果设置为 '0' 则一直接受请求. 等同于 PHP_FCGI_MAX_REQUESTS 环境变量. 默认值: 0.
pm.status_path = /php-fpm-status-web1                                                 ;FPM状态页面的网址. 如果没有设置, 则无法访问状态页面. 默认值: none. munin监控会使用到
ping.path = /php-fpm-ping-web1                                                        ;FPM监控页面的ping网址. 如果没有设置, 则无法访问ping页面. 该页面用于外部检测FPM是否存活并且可以响应请求. 请注意必须以斜线开头 (/)
ping.response = pong                                                                  ;用于定义ping请求的返回相应. 返回为 HTTP 200 的 text/plain 格式文本. 默认值: pong.
request_terminate_timeout = 60s                                                       ;设置单个请求的超时中止时间. 该选项可能会对php.ini设置中的'max_execution_time'因为某些特殊原因没有中止运行的脚本有用. 设置为 '0' 表示 'Off'.当经常出现502错误时可以尝试更改此选项。
request_slowlog_timeout = 60s                                                         ;当一个请求该设置的超时时间后，就会将对应的PHP调用堆栈信息完整写入到慢日志中. 设置为 '0' 表示 'Off'
slowlog = /var/log/php-fpm/www-slow.log                                               ;慢请求的记录日志,配合request_slowlog_timeout使用，默认关闭
rlimit_files = 10240                                                                  ;设置文件打开描述符的rlimit限制. 默认值: 系统定义值默认可打开句柄是1024，可使用 ulimit -n查看，ulimit -n 2048修改。
security.limit_extensions = .php .php3 .php4 .php5                                    ;设置php允许执行的文件，默认只允许执行.php文件。
php_admin_value[error_log] = /var/log/php-fpm/www-error.log                           ;php_admin_value[error_log] 参数 会覆盖php.ini中的 error_log 参数
php_admin_flag[log_errors] = on                                                       ;记录错误信息(保存到日志文件中)
php_admin_value[date.timezone] = Asia/Shanghai                                        ;增加参数，默认 date.timezone 是被注释掉的，也就是默认时区是 utc,设置php时区
php_value[session.save_handler] = files                                               ;session的存储方式
php_value[session.save_path] = /var/lib/php/session                                   ;session id存放路径
php_admin_value[memory_limit] = 512M                                                  ;memory_limit主要是为了防止程序错误，或者死循环占用大量的内存，导致系统宕机。在引入大量三方插件，或者代码时，进行内存限制就非常有必要了。
;php_admin_value[disable_functions] = exec,popen,system,passthru,shell_exec,escapeshellarg,escapeshellcmd,proc_close,proc_open
;使用disable_functions限制程序使用一些可以直接执行系统命令的函数如system，exec，passthru，shell_exec，proc_open等等。
;php_admin_value[disable_functions] = passthru,exec,system,chroot,scandir,chgrp,chown,shell_exec,proc_open,proc_get_status,ini_alter,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server
;php_admin_value[open_basedir] =  /data/www/:/tmp/:/home/www/
;upload_tmp_dir 的这个参数为上传文件的临时目录，需要 php 进程有读写权限。
php_admin_value[upload_tmp_dir] =  /tmp
EOF
}
#mysql 配置文件
function mysql5_conf(){
  mysql_data=/data/mysql
  mysql_conf=/etc/my.cnf
  #创建mysql数据库目录
  if [ ! -d ${mysql_data} ]; then
    mkdir -p ${mysql_data}/data
    mkdir -p ${mysql_data}/log
    mkdir -p ${mysql_data}/tmp
    chown -R mysql.mysql ${mysql_data}
  fi
#生成mysql配置文件my.conf
cat << EOF >${mysql_conf}
############################################################################################
#                                                                                          #
#Author: xiao.li                                                                           #
#Date: 2017-03-17                                                                          #
#version:0.0.1                                                                             #
#Description: my.cnf 阿里云dba数据库优化                                                   #
#Alter:                                                                                    #
############################################################################################
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
innodb_buffer_pool_size=1G
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
  chmod 755 ${mysql_conf}
  #初始化mysql数据库
  if [ ! -d ${mysql_data}/data/mysql ]; then
    /usr/bin/mysql_install_db --defaults-extra-file=${mysql_conf} --user=mysql --force >/dev/null >&1
  fi
  #设置mysql宽松模式
  # if [ -f /usr/my.cnf ]; then
  #     rm -f /usr/my.cnf
  # fi
  #修正Centos7 mysql连接数限制
cat << EOF >/usr/lib/systemd/system/mysqld.service
#
# Simple MySQL systemd service file
#
# systemd supports lots of fancy features, look here (and linked docs) for a full list:
#   http://www.freedesktop.org/software/systemd/man/systemd.exec.html
#
# Note: this file ( /usr/lib/systemd/system/mysql.service )
# will be overwritten on package upgrade, please copy the file to
#
#  /etc/systemd/system/mysql.service
#
# to make needed changes.
#
# systemd-delta can be used to check differences between the two mysql.service files.
#

[Unit]
Description=MySQL Community Server
After=network.target
After=syslog.target

[Install]
WantedBy=multi-user.target
Alias=mysql.service

[Service]
User=mysql
Group=mysql

# Execute pre and post scripts as root
PermissionsStartOnly=true

# Needed to create system tables etc.
ExecStartPre=/usr/bin/mysql-systemd-start pre

# Start main service
ExecStart=/usr/bin/mysqld_safe --basedir=/usr

# Don't signal startup success before a ping works
ExecStartPost=/usr/bin/mysql-systemd-start post

# Give up if ping don't get an answer
TimeoutSec=600

Restart=always
PrivateTmp=false
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
# Centos 安装nginx
function install_nginx(){
  if [[ $cmd == "yum" ]]; then
    if [[ ${VERSION_ID} == 8 ]]; then
      $cmd install -y http://nginx.org/packages/centos/8/x86_64/RPMS/nginx-1.16.1-1.el8.ngx.x86_64.rpm
      nginx_conf
    else
      $cmd install -y epel-release  >/dev/null
      $cmd install -y http://nginx.org/packages/centos/${VERSION_ID}/noarch/RPMS/nginx-release-centos-${VERSION_ID}-0.el${VERSION_ID}.ngx.noarch.rpm
      $cmd install -y nginx >/dev/null
      nginx_conf
    fi
  fi
}
# Centos 安装php5.6
function install_php56(){
  if [[ $cmd == "yum" ]]; then
    $cmd install -y epel-release  >/dev/null
    $cmd install -y https://mirror.webtatic.com/yum/el${VERSION_ID}/webtatic-release.rpm
    $cmd install -y php56w php56w-bcmath php56w-cli php56w-common php56w-dba php56w-devel php56w-embedded php56w-enchant php56w-fpm php56w-gd php56w-imap\
    php56w-interbase php56w-intl php56w-ldap php56w-mbstring php56w-mcrypt php56w-mssql php56w-mysql php56w-odbc php56w-opcache php56w-pdo php56w-pear\
    php56w-pecl-apcu php56w-pecl-apcu-devel php56w-pecl-gearman php56w-pecl-geoip php56w-pecl-igbinary php56w-pecl-igbinary-devel php56w-pecl-imagick php56w-pecl-imagick-devel\
    php56w-pecl-memcache php56w-pecl-memcached php56w-pecl-mongodb php56w-pecl-redis php56w-pecl-xdebug php56w-pgsql php56w-phpdbg php56w-process php56w-pspell php56w-recode php56w-snmp\
    php56w-soap php56w-tidy php56w-xml php56w-xmlrpc
    php_fpm_conf
  fi
}
# Centos安装php7.2
function install_php72(){
  if [[ $cmd == "yum" ]]; then
    $cmd install -y epel-release  >/dev/null
    $cmd install -y https://mirror.webtatic.com/yum/el${VERSION_ID}/webtatic-release.rpm
    $cmd install -y mod_php72w php72w-bcmath php72w-cli php72w-common php72w-dba php72w-devel php72w-embedded php72w-enchant php72w-fpm\
      php72w-gd php72w-imap php72w-interbase php72w-intl php72w-ldap php72w-mbstring php72w-mysql php72w-odbc php72w-opcache php72w-pdo php72w-pdo_dblib\
      php72w-pear php72w-pecl-apcu php72w-pecl-apcu-devel php72w-pecl-geoip php72w-pecl-igbinary php72w-pecl-igbinary-devel php72w-pecl-imagick php72w-pecl-imagick-devel\
      php72w-pecl-libsodium php72w-pecl-memcached php72w-pecl-mongodb php72w-pecl-redis php72w-pecl-xdebug php72w-pgsql php72w-phpdbg php72w-process php72w-pspell php72w-recode\
      php72w-snmp php72w-soap php72w-sodium php72w-tidy php72w-xml php72w-xmlrpc
      php_fpm_conf
  fi
}
# Centos安装mysql5.6
function install_mysql56(){
  if [[ $cmd == "yum" ]]; then
    $cmd install -y epel-release  >/dev/null
    $cmd install -y https://repo.mysql.com/yum/mysql-5.6-community/el/${VERSION_ID}/${sys_bit}/mysql-community-release-el${VERSION_ID}-5.noarch.rpm
    $cmd install -y mysql-community-client mysql-community-common mysql-community-devel mysql-community-server mysql-community-test >/dev/null
    mysql5_conf
  fi
}
# Centos安装mysql5.7
function install_mysql57(){
  if [[ $cmd == "yum" ]]; then
    $cmd install -y epel-release  >/dev/null
    $cmd install -y https://repo.mysql.com/yum/mysql-5.7-community/el/${VERSION_ID}/${sys_bit}/mysql-community-release-el${VERSION_ID}-7.noarch.rpm
    $cmd install -y mysql-community-client mysql-community-common mysql-community-devel mysql-community-server mysql-community-test >/dev/null
    mysql5_conf
  fi
}
# Centos 安装mysql8.0
function install_mysql80(){
  if [[ $cmd == "yum" ]]; then
    $cmd install -y epel-release  >/dev/null
    $cmd install -y https://repo.mysql.com/yum/mysql-8.0-community/el/${VERSION_ID}/${sys_bit}/mysql80-community-release-el${VERSION_ID}-3.noarch.rpm
    $cmd install -y mysql-community-client mysql-community-common mysql-community-devel mysql-community-server mysql-community-test >/dev/null
  fi
}

#Centos 环境检测
function check_env(){
  if [[ $(command -v nginx) ]]; then
    nginx_ver=$(nginx -v 2>&1| awk -F":" '{print $2}' | tr -d " "|awk -F'/' '{print $2}')
  	echo -n "  nginx已安装，nginx版本:${nginx_ver}"
  fi
  if [[ $(command -v php) ]]; then
    php_ver=$(php -v|head -1|awk '{print $2}')
    echo -n  "  php已安装，php版本:${php_ver}"
  fi
  if [[ $(command -v mysqld) ]]; then
    mysql_ver=$(mysqld -V|awk '{print $3}')
    echo -n  "  mysql已安装，mysql版本:${mysql_ver}"
  fi
}

menu() {
	clear
	while :; do
		echo
		echo "........... LNMP 安装脚本 $_version by xiao.li .........."
		echo
		echo "帮助说明: "
		echo
		echo "反馈问题: "
		echo
		echo "捐赠脚本作者: "
		echo
		echo "........................................................"
		echo
		echo -e "$green $(check_env)"
		echo
		echo -e "$yellow  1. $none安装 nginx"
		echo
		echo -e "$yellow  2. $none安装 php5.6"
		echo
		echo -e "$yellow  3. $none安装 php7.2"
		echo
		echo -e "$yellow  4. $none安装 mysql5.6"
		echo
		echo -e "$yellow  5. $none安装 mysql5.7"
		echo
		echo -e "$yellow  6. $none安装 mysql8.0"
		echo
		echo -e "温馨提示...如果你不想执行选项...按$yellow Ctrl + C $none即可退出"
		echo
		read -p "$(echo -e "请选择菜单 [${magenta}1-6$none]:")" choose
		if [[ -z $choose ]]; then
			exit 1
		else
			case $choose in
			1)
				install_nginx
				break
				;;
			2)
				install_php56
				break
				;;
			3)
				install_php72
				break
				;;
			4)
				install_mysql56
				break
				;;
			5)
				install_mysql57
				break
				;;
			6)
				install_mysql80
				break
				;;
			*)
				error
				;;
			esac
		fi
	done
}
menu
