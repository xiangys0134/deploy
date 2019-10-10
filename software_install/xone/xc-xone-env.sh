#!/bin/bash
# xone在线安装
# Author Yousong.Xiang
# Date 2019.10.10
# v1.0.1

[ -f /etc/profile ] && . /etc/profile

#检查安装环境
function env_check() {
if [ -f /var/log/xc-xone-env.log ];then
    echo -e "\033[31;49;1m[`date +%F' '%T`] Error: 此系统已经部署过业务,请检查。 \033[39;49;0m"
    echo -e "\033[31;49;1m[`date +%F' '%T`] Error:  `awk  '{print $1,$2,$3}' /var/log/xc-xone-env.log` \033[39;49;0m"
    exit 1
fi
}

#检查rpm包是否安装
function check_rpm() {
    rpm_name=$1
    num=`rpm -qa | grep ^${rpm_name} |wc -l`
    echo ${num}
}

#安装redhat-lsb-core
function lsb_install() {
    #关闭selinux
    sed  -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0

    if [ "`check_rpm redhat-lsb-core`" == "0" ]; then
        yum install -y redhat-lsb-core >/dev/null 2>&1
        if [ "`check_rpm redhat-lsb-core`" != "0" ]; then
            echo -e "\033[32m安装redhat-lsb-core成功\033[0m"
        else
            echo -e "\033[31m安装redhat-lsb-core失败\033[0m"
        fi
    fi
}

function nginx_conf() { 
    #num=$1 
    fastcgi_conf=/etc/nginx/fastcgi.conf

    [ ! -f /etc/nginx ] && mkdir /etc/nginx -p
    [ ! -f /etc/nginx/conf.d ] && mkdir /etc/nginx/conf.d -p

    #如果num变量为空时，num赋值为1
    if [ -z "${num}" ]; then
        num=1
    fi

    #生成fastcgi.conf文件
    if [ ! -f ${fastcgi_conf} ]; then
        cat >>${fastcgi_conf}<< EOF
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
fastcgi_param  SERVER_SOFTWARE    nginx/$nginx_version;
fastcgi_param  REMOTE_ADDR        \$remote_addr;
fastcgi_param  REMOTE_PORT        \$remote_port;
fastcgi_param  SERVER_ADDR        \$server_addr;
fastcgi_param  SERVER_PORT        \$server_port;
fastcgi_param  SERVER_NAME        \$server_name;
# PHP only, required if PHP was built with --enable-force-cgi-redirect
fastcgi_param  REDIRECT_STATUS    200;
# fastcgi_param  PHP_VALUE      "open_basedir=\$document_root:/tmp/";
EOF
    else
        echo "\033[31m${fastcgi_conf}已经存在!\033[0m"
    fi
}


function nginx_install() {
    #num=$1
    sys_ver=`lsb_release -r |awk -F' ' '{print $2}'|awk -F'.' '{ print $1 }'`
    if [ "`check_rpm nginx-1`" != "0" ]; then
        echo -e "\033[32mnginx已经安装，请检查确认\033[0m" 
        return 0
    fi

    if [ "`check_rpm nginx-release`" == "0" ]; then
        rpm -ivh http://nginx.org/packages/centos/${sys_ver}/noarch/RPMS/nginx-release-centos-${sys_ver}-0.el${sys_ver}.ngx.noarch.rpm >/dev/null >&1
        if [ "`check_rpm nginx-release`" != "0" ]; then
            echo -e "\033[32mnginx源安装成功\033[0m"
        else
            echo -e "\033[31mnginx源安装失败\033[0m"
        fi
    else
        echo -e "\033[31m已存在nginx源\033[0m" 
    fi
   
    if [ `check_rpm  nginx-1` == 0 ]; then
        yum install -y nginx ImageMagick >/dev/null >&1
        if [ `check_rpm  nginx-1` != 0 ]; then
            echo -e "\033[32mnginx安装成功\033[0m"
        else
            echo -e "\033[31mnginx安装失败\033[0m"
        fi
    fi
    nginx_conf
}

#安装jdk
function jdk_install() {
    if [ `check_rpm  java-1.8.0-openjdk` != 0 ]; then
        echo -e "\033[32mjava-1.8.0-openjdk已经安装，请检查确认\033[0m"
        return 0
    fi
    yum install java-1.8.0-openjdk -y
    if [ `check_rpm  java-1.8.0-openjdk` != 0 ]; then
        echo -e "\033[32mjava-1.8.0-openjdk安装成功\033[0m"
    else
        echo -e "\033[31mjava-1.8.0-openjdk安装失败\033[0m"
    fi
}

#redis.conf
function redis_conf() {
    redis_port=$1
    redis_data=$2
    redis_cf=${redis_data}/conf/redis-${redis_port}.conf
    redis_shutdown=/usr/libexec/redis-shutdown
    redis_service=/usr/lib/systemd/system/redis-${redis_port}.service
    redis_ip=0.0.0.0
    
    if [ ! -f ${redis_cf} ]; then
        cat >>${redis_cf}<< EOF
######Master config
###General 配置

# 是否以守护模式启动，默认为no，配置为yes时以守护模式启动，这时redis instance会将进程号pid写入默认文件/var/run/redis.pid。
daemonize yes

# 配置pid文件路径。当redis以守护模式启动时，如果没有配置pidfile，pidfile默认值是/var/run/redis.pid 。
pidfile "/var/run/redis-${redis_port}.pid"

#默认情况下，redis 在 server 上所有有效的网络接口上监听客户端连接。如果只想让它在一个或多个网络接口上监听，那你就绑定一个IP或者多个IP。多个ip空格分隔即可。
#bind 127.0.0.1  ${redis_ip}

# 指定该redis server监听的端口号。默认是6379，如果指定0则不监听。
port ${redis_port}

# 此参数确定了TCP连接中已完成队列(完成三次握手之后)的长度， 当然此值必须不大于Linux系统定义的/proc/sys/net/core/somaxconn值，默认是511，而Linux的默认参数值是128。当系统并发量大并且客户端速度缓慢的时候，可以将这二个参数一起参考设定。
tcp-backlog 511

# 当客户端闲置多少秒后关闭连接，如果设置为0表示关闭该功能。
timeout 300

# 单位是秒，表示将周期性的使用SO_KEEPALIVE检测客户端是否还处于健康状态，避免服务器一直阻塞，官方给出的建议值是300S
tcp-keepalive 0

# 日志级别。可选项有：debug（记录大量日志信息，适用于开发、测试阶段）；  verbose（较多日志信息）；  notice（适量日志信息，使用于生产环境）；warning（仅有部分重要、关键信息才会被记录）。
loglevel debug

# 日志文件的位置，当指定为空字符串时，为标准输出，如果redis已守护进程模式运行，那么日志将会输出到  /dev/null 。
logfile "${redis_data}/log/redis-${redis_port}.log"

# 设置数据库的数目。默认的数据库是DB 0 ，可以在每个连接上使用select  <dbid> 命令选择一个不同的数据库，dbid是一个介于0到databases - 1 之间的数值。
databases 16

# 保存数据到磁盘。格式是：save <seconds> <changes> ，含义是在 seconds 秒之后至少有 changes个keys 发生改变则保存一次。
save 900 1
save 300 10
save 60 10000

# 默认情况下，如果 redis 最后一次的后台保存失败，redis 将停止接受写操作，这样以一种强硬的方式让用户知道数据不能正确的持久化到磁盘， 否则就会没人注意到灾难的发生。 如果后台保存进程重新启动工作了，redis 也将自动的允许写操作。然而你要是安装了靠谱的监控，你可能不希望 redis 这样做，那你就改成 no 好了。
stop-writes-on-bgsave-error yes

# 是否在dump  .rdb数据库的时候压缩字符串，默认设置为yes。如果你想节约一些cpu资源的话，可以把它设置为no，这样的话数据集就可能会比较大。
rdbcompression yes

# 是否CRC64校验rdb文件，会有一定的性能损失（大概10%）。
rdbchecksum yes

# rdb文件的名字。
dbfilename "dump-${redis_port}.rdb"

# 数据库存放目录。必须是一个目录，aof文件也会保存到该目录下。
dir "${redis_data}/data"

# 设置redis连接密码。
#requirepass "intel.com"

# 设置本机为slave服务。格式：slaveof <masterip> <masterport>。设置master服务的IP地址及端口，在Redis启动时，它会自动从master进行数据同步。
# slaveof 192.168.0.1 6379

# 当master服务设置了密码保护时，slav服务连接master的密码
#masterauth "intel.com"

# 当一个slave与master失去联系时，或者复制正在进行的时候，slave应对请求的行为：1) 如果为 yes（默认值） ，slave 仍然会应答客户端请求，但返回的数据可能是过时，或者数据可能是空的在第一次同步的时候；2) 如果为 no ，在你执行除了 info 和 salveof 之外的其他命令时，slave 都将返回一个 "SYNC with master in progress" 的错误。
slave-serve-stale-data yes

# 设置slave是否是只读的。从2.6版起，slave默认是只读的
slave-read-only yes

# 指定slave定期ping master的周期，默认10秒钟。
repl-ping-slave-period 10

# 设置主库批量数据传输时间或者ping回复时间间隔，默认值是60秒 。
repl-timeout 60

#指定向slave同步数据时，是否禁用socket的NO_DELAY选 项。若配置为“yes”，则禁用NO_DELAY，则TCP协议栈会合并小包统一发送，这样可以减少主从节点间的包数量并节省带宽，但会增加数据同步到 slave的时间。若配置为“no”，表明启用NO_DELAY，则TCP协议栈不会延迟小包的发送时机，这样数据同步的延时会减少，但需要更大的带宽。 通常情况下，应该配置为no以降低同步延时，但在主从节点间网络负载已经很高的情况下，可以配置为yes。
repl-disable-tcp-nodelay no

# 设置主从复制backlog容量大小。这个 backlog 是一个用来在 slaves 被断开连接时存放 slave 数据的 buffer，所以当一个 slave 想要重新连接，通常不希望全部重新同步，只是部分同步就够了，仅仅传递 slave 在断开连接时丢失的这部分数据。这个值越大，salve 可以断开连接的时间就越长。
repl-backlog-size 1mb

# 配置当master和slave失去联系多少秒之后，清空backlog释放空间。当配置成0时，表示永远不清空。
repl-backlog-ttl 3600

# 当 master 不能正常工作的时候，Redis Sentinel 会从 slaves 中选出一个新的 master，这个值越小，就越会被优先选中，但是如果是 0 ， 那是意味着这个 slave 不可能被选中。 默认优先级为 100。
slave-priority 100

# 设置客户端最大并发连接数，默认无限制，Redis可以同时打开的客户端连接数为Redis进程可以打开的最大文件描述符数-32（redis server自身会使用一些），如果设置 maxclients 0，表示不作限制。当客户端连接数到达限制时，Redis会关闭新的连接并向客户端返回max number of clients reached错误信息。
maxclients 5000

# 指定Redis最大内存限制，Redis在启动时会把数据加载到内存中，达到最大内存后，Redis会先尝试清除已到期或即将到期的Key，当此方法处理 后，仍然到达最大内存设置，将无法再进行写入操作，但仍然可以进行读取操作。Redis新的vm机制，会把Key存放内存，Value会存放在swap区，格式：maxmemory <bytes>　。
maxmemory 1953125kb

# 是否启用aof持久化方式 。即是否在每次更新操作后进行日志记录，默认配置是no，即在采用异步方式把数据写入到磁盘，如果不开启，可能会在断电时导致部分数据丢失。
appendonly yes

# 更新日志文件名，默认值为appendonly.aof 。
appendfilename "appendonly-${redis_port}.aof"

# aof文件刷新的频率。有三种：
#             1）no 依靠OS进行刷新，redis不主动刷新AOF，这样最快，但安全性就差。
#             2) always 每提交一个修改命令都调用fsync刷新到AOF文件，非常非常慢，但也非常安全。
#             3) everysec 每秒钟都调用fsync刷新到AOF文件，很快，但可能会丢失一秒以内的数据。
appendfsync everysec

# 指定是否在后台aof文件rewrite期间调用fsync，默认为no，表示要调用fsync（无论后台是否有子进程在刷盘）。Redis在后台写RDB文件或重写AOF文件期间会存在大量磁盘IO，此时，在某些linux系统中，调用fsync可能会阻塞。
no-appendfsync-on-rewrite no

# 当AOF文件增长到一定大小的时候Redis能够调用 BGREWRITEAOF 对日志文件进行重写 。当AOF文件大小的增长率大于该配置项时自动开启重写。
auto-aof-rewrite-percentage 100

# 当AOF文件增长到一定大小的时候Redis能够调用 BGREWRITEAOF 对日志文件进行重写 。当AOF文件大小大于该配置项时自动开启重写。
auto-aof-rewrite-min-size 64mb

# redis在启动时可以加载被截断的AOF文件，而不需要先执行 redis-check-aof 工具。
aof-load-truncated yes

# 一个Lua脚本最长的执行时间，单位为毫秒，如果为0或负数表示无限执行时间，默认为5000。
lua-time-limit 5000

#cluster-enabled 选项用于开实例的集群模式
#cluster-enabled yes
#
#cluster-conf-file 选项则设定了保存节点配置文件的路径， 默认值为nodes.conf
#cluster-config-file nodes.conf
#
#节点互连超时的阀值 
#cluster-node-timeout 15000
#cluster-migration-barrier 1
#

# 其中slowlog-log-slower-than表示slowlog的划定界限，只有query执行时间大于slowlog-log-slower-than的才会定义成慢查询，才会被slowlog进行记录。slowlog-log-slower-than设置的单位是微妙，默认是10000微妙，也就是10ms
slowlog-log-slower-than 5000

# slowlog-max-len表示慢查询最大的条数，当slowlog超过设定的最大值后，会将最早的slowlog删除，是个FIFO队列
slowlog-max-len 1024

# 因为开启键空间通知功能需要消耗一些 CPU ， 所以在默认配置下， 该功能处于关闭状态,当 notify-keyspace-events 选项的参数为空字符串时，功能关闭。
notify-keyspace-events ""

# ADVANCED CONFIG 设置，下面的设置主要是用来节省内存的，我没有对它们做修改
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-entries 512
list-max-ziplist-value 64
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
hll-sparse-max-bytes 3000
activerehashing yes

# 说明：client output buffer限制，可以用来强制关闭传输缓慢的客户端。格式为client-output-buffer-limit 。class可以为normal、slave、pubsub。hard limit表示output buffer超过该值就直接关闭客户端。soft limit和soft seconds表示output buffer超过soft limit后只需soft seconds后关闭客户端连接。
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit slave 4gb 2gb 1800
client-output-buffer-limit pubsub 32mb 8mb 60

# redis执行任务的频率为1s除以hz。
hz 10

#在aof重写的时候，如果打开了aof-rewrite-incremental-fsync开关，系统会每32MB执行一次fsync。这对于把文件写入磁盘是有帮助的，可以避免过大的延迟峰值。
aof-rewrite-incremental-fsync yes
# Generated by CONFIG REWRITE
EOF
    fi

    if [ ! -f ${redis_service} ]; then
        cat >>${redis_service}<< EOF
[Unit]
Description=Redis persistent key-value database
After=network.target

[Service]
ExecStart=/usr/bin/redis-server ${redis_cf} --supervised systemd
ExecStop=/usr/libexec/redis-shutdown redis-${redis_port}
Type=notify
User=redis
Group=redis
RuntimeDirectory=redis
RuntimeDirectoryMode=0755
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
EOF
    fi

    if [ -f ${redis_shutdown} ]; then
        rm -rf ${redis_shutdown}

        cat >>${redis_shutdown}<<EOF
#!/bin/bash
#
# Wrapper to close properly redis and sentinel
test x"\$REDIS_DEBUG" != x && set -x

REDIS_CLI=/usr/bin/redis-cli

# Retrieve service name
SERVICE_NAME="\$1"
if [ -z "\$SERVICE_NAME" ]; then
   SERVICE_NAME=redis
fi

# Get the proper config file based on service name
CONFIG_FILE="${redis_data}/\$SERVICE_NAME.conf"

# Use awk to retrieve host, port from config file
HOST=\`awk '/^[[:blank:]]*bind/ { print $2 }' $CONFIG_FILE | tail -n1\`
PORT=\`awk '/^[[:blank:]]*port/ { print $2 }' $CONFIG_FILE | tail -n1\`
PASS=\`awk '/^[[:blank:]]*requirepass/ { print $2 }' $CONFIG_FILE | tail -n1\`
SOCK=\`awk '/^[[:blank:]]*unixsocket\s/ { print $2 }' $CONFIG_FILE | tail -n1\`

# Just in case, use default host, port
HOST=\${HOST:-127.0.0.1}
PORT=\${PORT:-6380}

#if [ "\$SERVICE_NAME" = redis ]; then
#    PORT=\${PORT:-6380}
#else
#    PORT=\${PORT:-6380}
#fi


# Setup additional parameters
# e.g password-protected redis instances
[ -z "\$PASS"  ] || ADDITIONAL_PARAMS="-a \$PASS"

# shutdown the service properly
if [ -e "\$SOCK" ] ; then
    \$REDIS_CLI -s \$SOCK \$ADDITIONAL_PARAMS shutdown
else
    \$REDIS_CLI -h \$HOST -p \$PORT \$ADDITIONAL_PARAMS shutdown
fi 
EOF
    fi
    /bin/echo never > /sys/kernel/mm/transparent_hugepage/enabled
    cat >>/etc/rc.local<< EOF
/bin/echo never > /sys/kernel/mm/transparent_hugepage/enabled
EOF

    /bin/systemctl enable redis-${redis_port}.service
    /bin/systemctl start redis-${redis_port}.service
    firewall-cmd --zone=public --add-port=${redis_port}/tcp --permanent
    firewall-cmd --reload
}

#安装redis
function redis_install() {
    redis_data=$1
    #redis_port="6380 6381"
    redis_port="6380"
    mirrors_url='mirrors.xuncetech.com'
    if [ `check_rpm yum-utils` == '0' ]; then
        yum install yum-utils -y
    fi
    if [ `check_rpm redis-4.0.10` != '0' ]; then
        echo -e "\033[32mredis已经安装，请检查确认\033[0m"
        return 0
    fi
    yum-config-manager --add-repo http://${mirrors_url}/xunce/xunce-dev/yum/el7/xunce-dev.repo
    yum install --enablerepo=xunce-dev redis-4.0.10 -y 
    if [ `check_rpm redis-4.0.10` != '0' ]; then
        echo -e "\033[32mredis安装成功\033[0m"
    else
        echo -e "\033[31mredis安装失败\033[0m"
    fi

    [ ! -d ${redis_data}/conf ] && mkdir ${redis_data}/conf -p
    [ ! -d ${redis_data}/data ] && mkdir ${redis_data}/data -p
    [ ! -d ${redis_data}/log ] && mkdir ${redis_data}/log -p

    chown -R redis.redis ${redis_data}

    #生成redis配置文件
    [ -f /usr/lib/systemd/system/redis-sentinel.service ] && rm -rf /usr/lib/systemd/system/redis-sentinel.service
    [ -f /usr/lib/systemd/system/redis.service ] && rm -rf /usr/lib/systemd/system/redis.service

    if [ ! -n "${redis_port}" ]; then
        redis_port=6380
    fi

    for port in ${redis_port}
    do
        redis_conf ${port} ${redis_data}
    done
}

#安装fastdfs
function fastdfs_install() {
    if [ `check_rpm fastdfs-5.11` != '0' ]; then
        echo -e "\033[32mfastdfs已经安装，请检查确认\033[0m"
        return 0
    fi
    yum install --enablerepo=xunce-dev fastdfs-5.11 -y
    if [ `check_rpm fastdfs-5.11` != '0' ]; then
        echo -e "\033[32mfastdfs安装成功\033[0m"
    else
        echo -e "\033[31mfastdfs安装失败\033[0m"
    fi
}

#安装mysql
function mysql56_install() {
    mysql_data=$1
    mysql_conf=/etc/my.cnf
    mysql_repo=/etc/yum.repos.d/mysql-community.repo
    mysql_gpg_key=/etc/pki/rpm-gpg/RPM-GPG-KEY-mysql


    if [ -f /var/log/mysql_install.lock ]; then
        echo -e "\033[31;1mMysql installed Already \033[0m" |tee -a ${log}
        return 0
    fi    

    sys_ver=`lsb_release -r |awk -F' ' '{print $2}'|awk -F'.' '{ print $1 }'`

    if [ ! -f ${mysql_repo} ]; then
        cat >>${mysql_repo}<< EOF
# Enable to use MySQL 5.6
[mysql56-community]
name=MySQL 5.6 Community Server
baseurl=http://mirrors.xuncetech.com/mysql-repo/yum/mysql-5.6-community/el/${sys_ver}/\$basearch/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql
EOF
    fi

  if [ ! -f ${mysql_gpg_key} ]; then
      wget http://repo.mysql.com/RPM-GPG-KEY-mysql -O /etc/pki/rpm-gpg/RPM-GPG-KEY-mysql 
  fi

  if [ `check_rpm mysql-server` == '0' ]; then
      #yum install -y mysql-community-client mysql-community-server mysql-community-devel mysql-community-test  >/dev/null >&1
      yum install -y mysql-community-client mysql-community-server mysql-community-devel mysql-community-test 
  fi

  if [ `check_rpm mysql-server` != '0' ]; then
      echo -e "\033[32;1mmysql install seccuess\033[0m" |tee -a ${log}
  else:
      echo -e "\033[31;1mmysql install fail\033[0m" |tee -a ${log}
  fi

  #创建mysql数据库目录
  [ ! -d ${mysql_data}/data ] && mkdir ${mysql_data}/data -p
  [ ! -d ${mysql_data}/log ] && mkdir ${mysql_data}/log -p
  [ ! -d ${mysql_data}/tmp ] && mkdir ${mysql_data}/tmp -p
  
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
#sql_mode=""
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
#log-slave-updates=1
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
innodb_buffer_pool_size=512M
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
      #/usr/bin/mysql_install_db --defaults-extra-file=${mysql_conf} --user=mysql --force >/dev/null >&1
      echo ${mysql_conf}
      /usr/bin/mysql_install_db --defaults-extra-file=${mysql_conf} --user=mysql --force
      if [ $? -eq 0 ]; then
          echo  "mysql数据库初始化成功" |tee -a ${log}
      else
          echo 'mysql数据库初始化失败' |tee -a ${log}
      fi
  else
      echo "mysql数据库已初始化，无需再次初始化." |tee -a ${log}
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

function success_install() {
    [ ! -f /var/log/xc-xone-env.log ] && touch /var/log/xc-xone-env.log 
}

redis_dir=/data/redis
mysql_dir=/data/mysql

env_check
lsb_install
nginx_install
redis_install ${redis_dir}
fastdfs_install
mysql56_install ${mysql_dir}
success_install

