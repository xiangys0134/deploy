#!/bin/bash
# Redis一键安装
# Author: yousong.xiang
# Date:  2018.11.26
# Version: v1.0.1

datetime=`date '+%H%M%S'`

cmd=`pwd`


function check_rpm() {
    rpm_name=$1
    num=`rpm -qa|grep ${rpm_name}|wc -l`
    echo ${num}
}

function epel_install() {
    #关闭selinux,安装基础依赖环境函数
    sed -i '/^SELINUX=.*/s/SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux
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
            echo -e "\033[32;1mepel-release install seccuess\033[0m" |tee -a ${log}
            yum clean all            
        else
            echo -e "\033[31;1mepel-release install fail\033[0m" |tee -a ${log}
        fi
    fi   

    if [ `check_rpm wget` == '0' ]; then
        yum install -y wget
    fi

}

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
bind ${redis_ip}

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
CONFIG_FILE="${redis_data}/conf/\$SERVICE_NAME.conf"

# Use awk to retrieve host, port from config file
HOST=\`awk '/^[[:blank:]]*bind/ { print \$2 }' \$CONFIG_FILE | tail -n1\`
PORT=\`awk '/^[[:blank:]]*port/ { print \$2 }' \$CONFIG_FILE | tail -n1\`
PASS=\`awk '/^[[:blank:]]*requirepass/ { print \$2 }' \$CONFIG_FILE | tail -n1\`
SOCK=\`awk '/^[[:blank:]]*unixsocket\s/ { print \$2 }' \$CONFIG_FILE | tail -n1\`

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

function redis_install() {
    redis_data=$1
    #redis_port="6380 6381"
    redis_port="6380 6381 6382 6383 6384"
    redis_cf=${redis_data}/conf/redis-${redis_port}.conf
    #判断是否安装redis,如果没有安装则安装
    epel_install
    yum --enablerepo=remi install -y redis >/dev/null >&1
    if [ $? -eq 0 ]; then
        echo -e "\033[32;1m redis install seccuess\033[0m" |tee -a ${log}
    else
        echo -e "\033[31;1m redis install fail\033[0m" |tee -a ${log}
    fi

    if [ ! -d ${redis_data} ]; then
        mkdir -p ${redis_data}/conf
        mkdir -p ${redis_data}/data
        mkdir -p ${redis_data}/log
    fi
    chown -R redis.redis ${redis_data}

    #生成redis配置文件
    if [ ! -n "${redis_port}" ]; then
        redis_port=6380
    fi

    for port in ${redis_port}
    do
        redis_conf ${port} ${redis_data}
    done
}


redis_dir=/data/redis
redis_install ${redis_dir}

