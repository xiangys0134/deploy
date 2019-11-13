#!/bin/bash
# php7.2 rpm包安装
# Author yousong.xiang 250919938@qq.com
# Date 2019.1.13
# v1.0.1

[ -f /etc/profile ] && . /etc/profile

cmd=`pwd`

check_rpm() {
    rpm_name=$1
    num=`rpm -qa|grep ${rpm_name}|wc -l`
    echo ${num}
}

epel_install() {
    #关闭selinux
    sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux
    setenforce 0
    #判断是否安装redhat-lsb-core
    if [ `check_rpm redhat-lsb-core` == 0 ]; then
        yum install -y redhat-lsb-core  >/dev/null >&1
    fi 
  
    #判断是否安装epel-release
    if [ `check_rpm epel-release` == 0 ]; then
        yum install -y epel-release  >/dev/null >&1
    fi 

    sys_ver=`lsb_release -r |awk -F' ' '{print $2}'|awk -F'.' '{ print $1 }'`
    
    #source /etc/profile
    #判断是否安装remi-release,如果没有安装则安装
    if [ `check_rpm remi-release` == 0 ]; then
        rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-${sys_ver}.rpm  &>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "\033[32;1mremi-release install seccuess\033[0m" |tee -a ${log}
        else
            echo -e "\033[31;1mremi-release install fail\033[0m" |tee -a ${log}
        fi
    fi   


}

php_fpm_conf() {
    num=$1
    php_ver=$2
    php_fpm_cf=$3
    username=nginx
  

    id nginx &>/dev/null 
    if [ $? -ne 0 ]; then
        groupadd nginx
        useradd -M -g nginx -s /sbin/nologin  nginx
    fi
    

    if [ ! -f ${php_fpm_cf} ]; then  
        echo "******************************************************************"
cat >>${php_fpm_cf}<< EOF
[web${num}]
;fpm监听端口，即nginx中php处理的地址，一般默认值即可。可用格式为: 'ip:port', 'port', '/path/to/unix/socket'. 每个进程池都需要设置。如果nginx和php在不同的机器上，分布式处理，就设置ip这里就可以了。
;listen = 127.0.0.1:9000
listen = /var/run/php-fpm/php-fpm-${php_ver}-web${num}.sock
;listen.allowed_clients = 127.0.0.1
;允许访问FastCGI进程的IP白名单，设置any为不限制IP，如果要设置其他主机的nginx也能访问这台FPM进程，listen处要设置成本地可被访问的IP。默认值是any。每个地址是用逗号分隔. 如果没有设置或者为空，则允许任何服务器请求连接。
;backlog数，设置 listen 的半连接队列长度，-1表示无限制，由操作系统决定，此行注释掉就行。
listen.backlog = 2048
;unix socket设置选项，如果使用tcp方式访问，这里注释即可。 
listen.owner = ${username}
listen.group = ${username}
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
pm.max_children = 256                                                                 ;子进程最大数
pm.start_servers = 15                                                                 ;启动时的进程数，默认值为: min_spare_servers + (max_spare_servers - min_spare_servers) / 2
pm.min_spare_servers = 15                                                             ;保证空闲进程数最小值，如果空闲进程小于此值，则创建新的子进程
pm.max_spare_servers = 30                                                             ;保证空闲进程数最大值，如果空闲进程大于此值，此进行清理
pm.max_requests = 500                                                                 ;设置每个子进程重生之前服务的请求数. 对于可能存在内存泄漏的第三方模块来说是非常有用的. 如果设置为 '0' 则一直接受请求. 等同于 PHP_FCGI_MAX_REQUESTS 环境变量. 默认值: 0.
pm.status_path = /php-fpm-${num}-status-web2                                          ;FPM状态页面的网址. 如果没有设置, 则无法访问状态页面. 默认值: none. munin监控会使用到
ping.path = /php-fpm-${num}-ping-web2                                                 ;FPM监控页面的ping网址. 如果没有设置, 则无法访问ping页面. 该页面用于外部检测FPM是否存活并且可以响应请求. 请注意必须以斜线开头 (/)
ping.response = pong                                                                  ;用于定义ping请求的返回相应. 返回为 HTTP 200 的 text/plain 格式文本. 默认值: pong.
request_terminate_timeout = 60s                                                       ;设置单个请求的超时中止时间. 该选项可能会对php.ini设置中的'max_execution_time'因为某些特殊原因没有中止运行的脚本有用. 设置为 '0' 表示 'Off'.当经常出现502错误时可以尝试更改此选项。
request_slowlog_timeout = 60s                                                         ;当一个请求该设置的超时时间后，就会将对应的PHP调用堆栈信息完整写入到慢日志中. 设置为 '0' 表示 'Off'
slowlog = /var/log/php-fpm/www-slow.log                                               ;慢请求的记录日志,配合request_slowlog_timeout使用，默认关闭
rlimit_files = 10240                                                                  ;设置文件打开描述符的rlimit限制. 默认值: 系统定义值默认可打开句柄是1024，可使用 ulimit -n查看，ulimit -n 2048修改。
security.limit_extensions = .php .php3 .php4 .php5                                    ;设置php允许执行的文件，默认只允许执行.php文件。
php_admin_value[error_log] = /var/log/php-fpm/www-${num}-error.log                    ;php_admin_value[error_log] 参数 会覆盖php.ini中的 error_log 参数
php_admin_flag[log_errors] = on                                                       ;记录错误信息(保存到日志文件中)
php_admin_value[date.timezone] = Asia/Shanghai                                        ;增加参数，默认 date.timezone 是被注释掉的，也就是默认时区是 utc,设置php时区
php_value[session.save_handler] = files                                               ;session的存储方式
php_value[session.save_path] = /var/lib/php/session                                   ;session id存放路径
php_admin_value[upload_max_filesize] = 20M
php_admin_value[post_max_size] = 20M
php_admin_value[memory_limit] = 256M                                                  ;memory_limit主要是为了防止程序错误，或者死循环占用大量的内存，导致系统宕机。在引入大量三方插件，或者代码时，进行内存限制就非常有必要了。
;php_admin_value[disable_functions] = exec,popen,system,passthru,shell_exec,escapeshellarg,escapeshellcmd,proc_close,proc_open
;使用disable_functions限制程序使用一些可以直接执行系统命令的函数如system，exec，passthru，shell_exec，proc_open等等。
;php_admin_value[disable_functions] = passthru,exec,system,chroot,scandir,chgrp,chown,shell_exec,proc_open,proc_get_status,ini_alter,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server
;php_admin_value[open_basedir] =  /data/www/:/tmp/:/home/www/
;upload_tmp_dir 的这个参数为上传文件的临时目录，需要 php 进程有读写权限。
php_admin_value[upload_tmp_dir] =  /tmp 

EOF

    fi

    if [ $? -eq 0 ]; then
        echo -e "\033[32;1m生成$num:php-fpm配置文件成功\033[0m" |tee -a ${log}
    fi

}

install_php() {
    #以下两个变量可根据yum安装不同版本和socket进行调整
    #number=2
    #php_version=5.5

    [ -f /var/log/php_install.lock ] && {
                                            echo -e '\033[31;1mPHP Already installed\033[0m' |tee -a ${log}
                                            return 5
                                        }
    #安装epel源
    epel_install

    #添加yum源,下面的判定适用于自建yum源,对应的进行修改
    rpm -Uvh https://mirror.webtatic.com/yum/el7/epel-release.rpm
    rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
    
    #检查php72w是否安装
    if [ `check_rpm php72w-common` == 0 ]; then
        yum install php72w php72w-devel php72w-opcache php72w-mbstring php72w-mysqlnd php72w-fpm php72w-xml php72w-gd php72w-xmlrpc php72w-pecl-redis php72w-pecl-apcu php72w-bcmath php72w-pecl-igbinary php72w-soap php72w-pear php72w-pecl-xdebug php72w-pecl-mongodb openssl openssl-devel mysql-community-client gcc gcc-c++ make unzip autoconf wget -y
    fi 

    if [ $? -ne 0 ]; then
        echo "\033[31;1mphp install false\033[0m" |tee -a ${log}
        exit 6
    fi   

    if [ -z "${number}" ]; then
        let number=2
    fi 
    
    if [ -z "${php_version}" ]; then
        php_version=7.2
    fi

    [ -f /etc/php-fpm.d/www.conf ] && mv /etc/php-fpm.d/www.conf /etc/php-fpm.d/www.conf.default     

    let i=1
    while [ $i -le ${number} ]
    do
        php_fpm_conf $i ${php_version} /etc/php-fpm.d/web${i}.conf
        let i++
    done

   cd ${cmd}

   if [ -d ${cmd}/php-beast-master ]; then
       rm -rf ${cmd}/php-beast-master
   fi

   [ ! -f php-beast-master.zip ] && wget http://soft.g6p.cn/deploy/source/php-beast-master.zip
   unzip php-beast-master.zip
   cd ${cmd}/php-beast-master
   /usr/bin/phpize && ./configure --with-php-config=/usr/bin/php-config
   if [ $? -ne 0 ]; then
       echo -e "\033[31;1m phpize failed!\033[0m"
   else
       make && make install
   fi
   if [ -d /etc/php.d ]; then
       echo "extension=beast.so" > /etc/php.d/50-beast.ini
   fi  

}


install_php
